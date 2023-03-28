
"""
    ExcessReturn(market_returns::TSFrame)

This models basic scalar excess return.  
"""
struct ExcessReturn <: AbstractModel 
    market_returns::TSFrame
end

"""
    ConstantMeanReturn()

Each column is decreased by its mean.
"""
struct ConstantMeanReturn <: AbstractModel 
end

StatsBase.fit(c::ConstantMeanReturn, data) = c
StatsBase.fit!(c::ConstantMeanReturn, data) = c
function StatsBase.predict(c::ConstantMeanReturn, data::TSFrame)
    ret = deepcopy(data)
    for column in 2:size(data, 2)
        ret.coredata[!, column] .-= mean(data.coredata[!, column])
    end
    return ret
end