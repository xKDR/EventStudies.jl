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
"This means that the model's index type was incompatible with the event's index type."
struct ModelIndexIncompatible <: EventStatus end
"This means that the column name was not found in the data.  It prints the column name.  Equivalent to `unitmissing` in `eventstudies.R`."
struct InvalidColname <: EventStatus 
    colname::Symbol
end

# Base.show(io, ::MIME"text/plain", status::InvalidColname) = printstyled(io, "InvalidColname($(status.colname))", color = :red)

# write a helper function which converts an Int window into a range centered about zero, and a vector window into a vector of the same length centered about zero.
function window_to_range(window::Int)
    return collect(-window : 1 : window)
end

function window_to_range(window::AbstractVector{<: Integer})
    return collect(window)
end


"""
    to_eventtime_windowed(
        return_timeseries::TSFrame, 
        event_times::Vector{Pair{Symbol, T}}, 
        window::Int, 
        model::AbstractEventStudyModel = NoModel(); 
        debug = false
        ) where T

Takes in a `TSFrame` of returns, a vector of pairs of column names and event times, and a window size.  
It then returns a `TSFrame` of event windows, where each column is the event return for the corresponding event.  

## Arguments
- `return_timeseries` is a `TSFrame` which contains the returns of the assets.
- `event_times` is a vector of pairs, where the first element is the name of the column in `return_timeseries` and the second element is the time of the event.  This is in the form `:colname => date`.
- `window` is the number of data points before and after the event to include in the event window.  It may be an Integer, which describes a range `-window:1:window`.  It may also be an `AbstractVector` of Integers or `Dates.Period`s, which describes the exact window to use.
- `model` is an [`AbstractEventStudyModel`](@ref) which is used to transform the data before calculating the event returns.
- `debug` is a boolean which indicates whether to print debug information.
"""
function to_eventtime_windowed(return_timeseries::TSFrame, event_times::Vector{Pair{Symbol, T}}, window::Union{Integer, AbstractVector{<: Integer}}, model::AbstractEventStudyModel = NoModel(); debug = false) where T
    if window isa Integer
        @assert window ≥ 1 "The window must have a length greater than 1!  The provided window length was $window."
    end

    # initialize the return codes array
    event_return_codes = EventStatus[]
    # create an index vector which is of the same type as the index of `return_timeseries`.
    window_vec = window_to_range(window)
    index_vec = get_period_type(return_timeseries).(window_vec) .+ get_time_type(return_timeseries)(0)
    debug && show(IOContext(stdout, :compact => true), MIME("text/plain"), index_vec)

    # create an empty TSFrame with a populated index, to store the results
    event_timeseries = TSFrame(DataFrame(:Index => index_vec), :Index)


    # precomputed values for "bounds checking"/index validation
    minimum_index = abs(minimum(window_vec))
    maximum_index = length(return_timeseries) - maximum(window_vec)
    valid_column_names = Set(propertynames(return_timeseries.coredata)[2:end])

    # iterate over all events, process them and store the processed data in `event_timeseries`
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

        # extract the data (as a copy)
        new_data = return_timeseries[window_vec .+ event_time_index, [:Index, colname]]
        # check that none of the data is `missing`
        if any(ismissing.(getproperty(new_data, colname)))
            push!(event_return_codes, DataMissing())
            continue
        end

        # disambiguate the column name in case there are multiple events for the same column
        new_colname = string(colname) in names(event_timeseries) ? gensym(colname) : colname

        # Apply the model, if it exists
        new_data = TSFrame(return_timeseries.coredata[window_vec .+ event_time_index, [:Index, colname]], :Index; copycols = false, issorted = true)#new_data, success_code = apply_model(model, TSFrame(return_timeseries.coredata[!, [:Index, colname]], :Index; copycols = false, issorted = true), window_vec .+ event_time_index)
        # If the model failed, then skip this event, and log that!
        if success_code != Success()
            push!(event_return_codes, success_code)
            continue
        end
        debug && show(IOContext(stdout, :compact => true), MIME("text/plain"), new_data)
        # if all criteria check out, then assign the data to the tsframe,
        event_timeseries.coredata[!, new_colname] = getproperty(new_data, colname)
        # and record that this event was successful.
        push!(event_return_codes, Success())
    end
    # return the event timeseries and success codes
    return (event_timeseries, event_return_codes)
end

"""
    levels_to_returns(ts::TSFrame)::TSFrame

Converts the data in `ts` into "returns" data, i.e., executes `diff(log(ts)) .* 100` on each column of `ts`.
"""
function levels_to_returns(ts::TSFrame)
    # # first, apply log to the TSFrame's values
    # log_ts = Base.materialize(Base.broadcasted(x -> log.(ℯ, x), ts; renamecols = false))
    # # now, rename since TSFrames auto-renames when broadcasting
    # rename_sources = propertynames(log_ts.coredata[!, Not(:Index)])
    # rename_sinks = Symbol.(string.(rename_sources) .|> x -> x[1:end-4])
    # TSFrames.DataFrames.rename!(log_ts.coredata, (rename_sources .=> rename_sinks)...)
    # # finally, return diff(log)
    # return diff(log_ts) .* 100

    return_ts = TSFrame(ts.coredata[2:end, :], :Index; copycols = false, issorted = true)

    for colname in names(ts)
        return_ts.coredata[!, colname] = 100 .* diff(log.(ts.coredata[!, colname]))
    end

    return return_ts
end