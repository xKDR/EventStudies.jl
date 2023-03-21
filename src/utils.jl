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
