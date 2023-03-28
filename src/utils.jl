############################################################
#                Period and time utilities                 #
############################################################

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

############################################################
#                   Remapping functions                    #
############################################################

"""
    remap_cumsum(ts::TSFrame; base = 0)

This function remaps a time series into its cumulative summation. 
The first value of each column is set to `base`.
"""
function remap_cumsum(ts::TSFrame; base = 0)
    var"length(names(ts.coredata))" = length(names(ts.coredata))
    @assert var"length(names(ts.coredata))" > 1

    return_ts = TSFrame(ts.coredata; issorted = true, copycols = true)

    for col in 2:size(ts.coredata, 2)
        tmp = return_ts.coredata[:, col]
        tmp[1] = base
        return_ts.coredata[!, col] = cumsum(tmp) 
    end
    return return_ts
end

function test_remap_cumsum()
    ts = TSFrame(rand(100, 10), Date(2000, 1, 1):Day(1):Date(2000, 4, 9))
    remap_cumsum(ts)
end

"""
    remap_levels(ts::TSFrame, base = 100)

"""
function remap_levels(ts::TSFrame, base = 100)
    return_ts = deepcopy(ts)
    event_ind = length(return_ts)÷2
    for column in names(ts)
        return_ts.coredata[!, column] .*= base/return_ts.coredata[event_ind, column] 
    end
    return return_ts
end


function test_remap_levels()
    ts = TSFrame(rand(100, 10), Date(2000, 1, 1):Day(1):Date(2000, 4, 9))
    remap_levels(ts)
end

function Base.cumsum(ts::TSFrame, dims::Int = 1)
    if dims == 1
        return col_cumsum(ts)
    elseif dims == 2
        return row_cumsum(ts)
    else
        DimensionMismatch("A TSFrame has only 2 dimensions but you have asked for a cumsum along dimension $dims.")
    end
end

function col_cumsum(ts::TSFrame)
    new_ts = TSFrame(ts.coredata; copycols = true, issorted = true)
    for col in names(new_ts.coredata[!, Not(:Index)])
        new_ts.coredata[!, col] = cumsum(new_ts.coredata[!, col])
    end
    return new_ts
end

function row_cumsum(ts::TSFrame)
    new_ts = TSFrame(map(sum, eachrow(Matrix(ts))), ts.Index; copycols = false, issorted = true)
    return new_ts
end

############################################################
#                    Levels to returns                     #
############################################################

"""
    levels_to_returns(ts::TSFrame [, base = 100])::TSFrame

Converts the data in `ts` into "returns" data, i.e., executes `diff(log(ts)) .* base` on each column of `ts`.
"""
function levels_to_returns(ts::TSFrame, base = 100)
    # # first, apply log to the TSFrame's values
    # log_ts = Base.materialize(Base.broadcasted(x -> log.(ℯ, x), ts; renamecols = false))
    # # now, rename since TSFrames auto-renames when broadcasting
    # rename_sources = propertynames(log_ts.coredata[!, Not(:Index)])
    # rename_sinks = Symbol.(string.(rename_sources) .|> x -> x[1:end-4])
    # TSFrames.DataFrames.rename!(log_ts.coredata, (rename_sources .=> rename_sinks)...)
    # # finally, return diff(log)
    # return diff(log_ts) .* 100

    # slice the input TSFrame from the 2nd row to the last
    # since `diff` consumes the first row
    return_ts = TSFrame(ts.coredata[2:end, :], :Index; copycols = false, issorted = true)

    for colname in names(ts)
        return_ts.coredata[!, colname] = base .* diff(log.(ts.coredata[!, colname]))
    end

    return return_ts
end

# TSFrames-RData interop
# we could make this blursed type-piracy, but that seems too general :D
function zoo_to_tsframe(rv::RData.RVector{Float64, 0x0e})
    @assert rv.attr["class"].data[1] == "zoo" # this must be a zoo object!
    dims = haskey(rv.attr, "dim") ? rv.attr["dim"].data : length(rv.data)
    datamatrix = if any(isnan, rv.data)
        reshape(replace!(Vector{Union{Float64, Missing}}(rv.data), NaN=>missing), dims...)
    else
        reshape(rv.data, dims...)
    end
    # this is the difference factor between R and Julia date integers,
    # since Julia uses UTD
    index = if rv.attr["index"].attr["class"].data[1] == "Date"
        Dates.Date.(Dates.UTD.(rv.attr["index"].data .+ 719163))
    elseif rv.attr["index"].attr["class"].data[1] == "POSIXct"
        RData.jlvec(RData.ZonedDateTime, rv.attr["index"], false)
    else
        rv.attr["index"].data
    end
    colnames = haskey(rv.attr, "dimnames") ? rv.attr["dimnames"].data[2].data : Symbol.(("x_",), 1:size(datamatrix, 2))
    return TSFrame(DataFrame(Symbol.(colnames) .=> eachcol(datamatrix)), index; copycols = false, issorted = true)
end