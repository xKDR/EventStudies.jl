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
# struct UnitMissing <: EventStatus end

function to_eventtime_windowed(return_timeseries::TSFrame, event_times::Vector{Pair{Symbol, T}}, window::Int, model::AbstractEventStudyModel = NoModel()) where T
    @assert window ≥ 1 "The window must have a length greater than 1!  The provided window length was $window."

    # initialize the return codes array
    event_return_codes = EventStatus[]
    # create an index vector which is of the same type as the index of `return_timeseries`.
    index_vec = collect(
        Base.StepRange(
            get_period_type(return_timeseries)(-window), 
            get_period_type(return_timeseries)(1), 
            get_period_type(return_timeseries)(window)
        ) .+ get_time_type(return_timeseries)(0)
    )
    # create an empty TSFrame with a populated index, to store the results
    event_timeseries = TSFrame(DataFrame(:Index => index_vec), :Index)
    show(IOContext(stdout, :compact => true), MIME("text/plain"), index_vec)

    # iterate over all events, process them and store the processed data in `event_timeseries`
    for (colname, event_time) in event_times
        # binary search for the event time
        event_time_index = searchsortedfirst(return_timeseries.Index, event_time)
        # check that the index is valid
        if event_time_index < window || event_time_index > length(return_timeseries) - window
            push!(event_return_codes, WrongSpan())
            continue
        end

        # extract the data (as a copy)
        new_data = TSFrame(return_timeseries.coredata[(event_time_index - window):(event_time_index + window), [:Index, colname]], :Index; copycols = false, issorted = false)
        # check that none of the data is `missing`
        if any(ismissing.(getproperty(new_data, colname)))
            push!(event_return_codes, DataMissing())
            continue
        end

        # disambiguate the column name in case there are multiple events for the same column
        new_colname = string(colname) in names(event_timeseries) ? gensym(colname) : colname

        # Apply the model, if it exists
        new_data, success_code = apply_model(model, new_data)
        # If the model failed, then skip this event, and log that!
        if success_code != Success()
            push!(event_return_codes, success_code)
            continue
        end
        show(IOContext(stdout, :compact => true), MIME("text/plain"), new_data)
        # if all criteria check out, then assign the data to the tsframe,
        event_timeseries.coredata[!, new_colname] = getproperty(new_data, colname)
        # and record that this event was successful.
        push!(event_return_codes, Success())
    end
    # return the event timeseries and success codes
    return (event_timeseries, event_return_codes)
end

"""
    levels_to_returns(ts::TSFrame)

Converts the data in `ts` into "returns" data, i.e., executes `diff(log(column)) .* 100`.
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

    return_ts = TSFrame(ts.coredata[2:end, :])

    for colname in names(ts)
        return_ts.coredata[!, colname] = 100 .* diff(log.(ts.coredata[!, colname]))
    end

    return return_ts
end