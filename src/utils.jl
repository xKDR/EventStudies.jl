
function remap_cumsum(ts::TSFrame; base = 0)
    var"length(names(ts.coredata))" = length(names(ts.coredata))
    @assert var"length(names(ts.coredata))" > 1

    return_ts = TSFrame(ts.coredata; issorted = true, copycols = true)

    for col in 2:var"length(names(ts.coredata))"
        tmp = return_ts.coredata[!, col]
        tmp[1] = base
        return_ts.coredata[!, col] = cumsum(tmp) 
    end
    return return_ts
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
