function get_period_type(tf::TSFrame)
    if eltype(tf.Index) <: Number
        return eltype(tf.Index)
    else
        return Day
    end
end

function get_time_type(tf::TSFrame)
    if eltype(tf.Index) <: Number
        return eltype(tf.Index)
    else
        return Date
    end
end

abstract type EventStatus end
"Represents a successful event"
struct Success <: EventStatus end
"This means that the span of the window extended outside the available data."
struct WrongSpan <: EventStatus end
"This means that there was missing data within the window."
struct DataMissing <: EventStatus end
struct UnitMissing <: EventStatus end

function to_eventtime_windowed(return_timeseries::TSFrame, event_times::Vector{Pair{Symbol, T}}, window::Int) where T
    # @assert length(unique(first.(event_times))) == length(event_times)
    @assert window ≥ 1

    event_return_codes = EventStatus[]

    # event_timeseries = TSFrame(get_period_type(return_timeseries); n = 1)
    index_vec = (Base.StepRange(get_period_type(return_timeseries)(-window), get_period_type(return_timeseries)(1), get_period_type(return_timeseries)(window)) .+ get_time_type(return_timeseries)(0)) |> collect
    event_timeseries = TSFrame(DataFrame(:Index => index_vec), :Index)
    # @show event_timeseries index_vec window
    # iterate over all events
    for (colname, event_time) in event_times
        # binary search for the event time
        event_time_index = searchsortedfirst(return_timeseries.Index, event_time)
        # check that the index is valid
        if event_time_index < window || event_time_index > length(return_timeseries) - window
            push!(event_return_codes, WrongSpan())
            continue
        end

        # extract the data (as a copy)
        new_data = return_timeseries.coredata[(event_time_index - window):(event_time_index + window), colname]
        # check that none of the data is `missing`
        if any(ismissing.(new_data))
            push!(event_return_codes, DataMissing())
            continue
        end

        # disambiguate the column name in case there are multiple events for the same column
        new_colname = string(colname) in names(event_timeseries) ? gensym(colname) : colname

        # if all criteria check out, then assign the data to the tsframe,
        event_timeseries.coredata[!, new_colname] = nonmissingtype(eltype(new_data)).(new_data)
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