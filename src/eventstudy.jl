"""
    abstract type EventStatus

An abstract supertype for all event status types. 
These are used to indicate the status of an event 
(i.e., if it was successful or not, and if so why it was unsuccessful).
"""
abstract type EventStatus end
"Represents a successful event"
struct Success <: EventStatus end
"This means that the span of the window extended outside the available data."
struct WrongSpan <: EventStatus end
"This means that there was missing data within the window."
struct DataMissing <: EventStatus end
"This means that the model was missing data within the event time window."
struct ModelDataMissing <: EventStatus end
"This means that the data had a missing value after the model's prediction."
struct MissingAfterModel <: EventStatus end
"This means that the model's index type was incompatible with the event's index type."
struct ModelIndexIncompatible <: EventStatus end
"This means that the column name was not found in the data.  It prints the column name.  Equivalent to `unitmissing` in `eventstudies.R`."
struct InvalidColname <: EventStatus 
    colname::Symbol
end

using TimerOutputs

# Base.show(io, ::MIME"text/plain", status::InvalidColname) = printstyled(io, "InvalidColname($(status.colname))", color = :red)

# write a helper function which converts an Int window into a range centered about zero, and a vector window into a vector of the same length centered about zero.
function window_to_range(window::Int)
    return collect(-window : 1 : window)
end

function window_to_range(window::AbstractVector{<: Integer})
    return collect(window)
end

# Allow any Tables.jl table to be used in `physical_to_event_time`,
# by converting to a TSFrame
eventstudy(return_timeseries, event_times::Vector{Pair{Symbol, T}}, window::Union{Integer, AbstractVector{<: Integer}}, args...; kwargs...) where T = eventstudy(TSFrame(return_timeseries; copycols = false), event_times, window, args...; kwargs...)

"""
    eventstudy(
        return_timeseries::TSFrame, 
        event_times::Vector{Pair{Symbol, T}}, 
        window::Int, 
        model = nothing; 
        verbose = true
        ) where T

Takes in a `TSFrame` of returns, a vector of pairs of column names and event times, and a window size.  
It then returns a `TSFrame` of event windows, where each column is the event return for the corresponding event.  

## Arguments
- `return_timeseries` is a `TSFrame` which contains the returns of the assets.
- `event_times` is a vector of pairs, where the first element is the name of the column in `return_timeseries` and the second element is the time of the event.  This is in the form `:colname => date`.
- `window` is the number of data points before and after the event to include in the event window.  It may be an Integer, which describes a range `-window:1:window`.  It may also be an `AbstractVector` of Integers or `Dates.Period`s, which describes the exact window to use.
- `model` is the decorrelating function to apply.
- `verbose` is a boolean which indicates whether to print information about the event study.
"""
function eventstudy(
    return_timeseries::TSFrame, 
    event_times::Vector{Pair{Symbol, T}}, 
    window::Union{Integer, AbstractVector{<: Integer}},
    model = nothing,
    map_function::F = ThreadPools.qmap,
    ; 
    verbose = true,
    ) where {T, F}
    # to = Main.to
    if window isa Integer
        @assert window ≥ 1 "The window must have a length greater than 1!  The provided window length was $window."
    end

    window_vec = window_to_range(window)
    index_vec = get_period_type(return_timeseries).(window_vec) .+ get_time_type(return_timeseries)(0)

    # @timeit to "Physical to event time" begin
    # Convert from physical (real) to event time (centered around 0)
    event_tsframes, event_time_indices, event_return_codes = physical_to_event_time(return_timeseries, event_times, window_vec, model)
    # Make sure that at least one event was successful
    if !any(x -> x isa Success, event_return_codes)
        @warn "No events were successful!  Returning an empty TSFrame."
        return (TSFrame(DataFrame(), :Index), event_return_codes)
    end
    # end

    # @timeit to "Applying models" begin
    # mutate the event timeseries to apply the model
    applicable_event_indices = findall(x -> x isa Success, event_return_codes)
    # get the standard offset for the first window element 
    first_window_offset = first(window_vec)

    # Now, we handle the model (if any).
    # If there is no model, then we just return the event timeseries.
    if isnothing(model)
        # do nothing
    else
        # apply these events in parallel
        # In general, `map_function` will be `ThreadPools.qmap`,
        # but in certain cases if multithreading is not performing correctly,
        # the user can override that.
        map_function(zip(event_time_indices, event_tsframes)) do (event_time_index, event_data)
            colname = names(event_data)[1]
            # fit the model to all data before the window
            model = fit(model, return_timeseries[1:(event_time_index - first_window_offset), [Symbol(colname)]])
            # apply the model to the event data
            # `predict` returns a TSFrame in the same format as the input
            event_data.coredata[!, colname] = Models.StatsBase.predict(model, event_data).coredata[!, colname] 
        end
    end
    # end

    # @timeit to "Constructing return object" begin
    # create an empty TSFrame with a populated index, to store the results
    event_timeseries = TSFrame(rand(length(window_vec)), window_vec)
    select!(event_timeseries.coredata, :Index)
    # finally, push the events to the TSFrame, and add some metadata
    for (ts, event) in zip(event_tsframes, event_times[applicable_event_indices])
        # Find and disambiguate the column name
        original_colname = Symbol(names(ts)[1])
        colname = original_colname
        i = 1
        while hasproperty(event_timeseries, colname)
            colname = Symbol(original_colname, "_", string(i))
            i += 1
        end
        # Set the new column in the final `event_timeseries`
        event_timeseries.coredata[!, colname] = ts.coredata[!, original_colname]
        # Encode the event in metadata
        DataFrames.colmetadata!(event_timeseries.coredata, colname, "event", string(event); style = :note)
    end

    # end

    if verbose
        num_success = length(event_tsframes)
        @info """
        Out of $(length(event_times)) events, $(num_success) were successful 
        (i.e., no missing data, no invalid column names, and no invalid time spans).

        This is a success rate of $(round(100 * num_success / length(event_times), digits = 2))%.
        """
    end

    # return the event timeseries and success codes
    return (event_timeseries, event_return_codes)
end

"""
    physical_to_event_time(timeseries::TSFrame, event_times::Vector{Pair{Symbol, T}}, window::Union{Integer, AbstractVector{<: Integer}}, model = nothing) where T

Converts the input `TSFrame` to a vector of `TSFrame`s - one per successful event, centered around the event time.

Arguments are the same as `eventstudy`.  Note that `model` is not applied here, but its contents are checked to ensure that the model has data in that span.

Returns a tuple `(event_tsframes, event_time_indices, event_return_codes)`:
- `event_tsframes::Vector{TSFrame}`: a vector of `TSFrame`s, one per successful event.
- `event_time_indices::Vector{Int}`: the (integer) indices in `timeseries` of the events.
- `event_return_codes::Vector{EventStatus}`: the status of each event.  This is a vector of [`EventStudies.EventStatus`](@ref) objects, of the same length as the input `event_times`.
"""
function physical_to_event_time(return_timeseries::TSFrame, event_times::Vector{Pair{Symbol, T}}, window::Union{Integer, AbstractVector{<: Integer}}, model = nothing) where T

    # initialize the return codes array
    event_return_codes = EventStatus[]
    # create an index vector which is of the same type as the index of `return_timeseries`.
    window_vec = window_to_range(window)

    # precomputed values for "bounds checking"/index validation
    minimum_index = abs(minimum(window_vec))
    maximum_index = length(return_timeseries) - maximum(window_vec)
    valid_column_names = Set(propertynames(return_timeseries.coredata)[2:end])

    event_tsframes = TSFrame[]
    sizehint!(event_tsframes, length(event_times))
    event_time_indices = Int[]
    sizehint!(event_tsframes, length(event_times))

    # iterate over all events, process them and store the processed data in `event_timeseries`.

    # this is really fast, at the end we have a list of TSFrames whose events were valid.
    # You _could_ multithread this, but there isn't much point - it's fast enough as is for eventstudy like workloads.
    # Fitting the models is the really expensive part, which we do parallelize.
    for (colname, event_time) in event_times

        # Check that the column name is valid
        if !(colname in valid_column_names)
            push!(event_return_codes, InvalidColname(colname))
            continue
        end

        # binary search for the event time
        event_time_index = searchsortedfirst(return_timeseries.Index, event_time)
        
        # check that the index is valid
        if !(minimum_index ≤ event_time_index ≤ maximum_index)
            push!(event_return_codes, WrongSpan())
            continue
        end

        if !Models.check_window(model, window_vec, event_time)
            push!(event_return_codes, ModelDataMissing())
            continue
        end

        # extract the data (as a copy)
        new_data = return_timeseries[window_vec .+ event_time_index, [colname]]
        # check that none of the data is `missing`
        if any(ismissing.(getproperty(new_data, colname)))
            push!(event_return_codes, DataMissing())
            continue
        end

        # Construct the TSFrame for the event
        new_data = TSFrame(return_timeseries.coredata[window_vec .+ event_time_index, [:Index, colname]], :Index; copycols = false, issorted = true)#new_data, success_code = apply_model(model, TSFrame(return_timeseries.coredata[!, [:Index, colname]], :Index; copycols = false, issorted = true), window_vec .+ event_time_index)

        # if all criteria check out, then assign the data to the tsframe,
        push!(event_tsframes, new_data)
        # record the event time index, so we don't have to search again,
        push!(event_time_indices, event_time_index)
        # and record that this event was successful.
        push!(event_return_codes, Success())
    end

    return event_tsframes, event_time_indices, event_return_codes
end
