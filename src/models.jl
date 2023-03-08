
# Define event study decorrelation models
abstract type AbstractEventStudyModel end

"""
    MarketModel(market_returns::TSFrame)

Regresses "market" returns on the variable using a linear model.
"""
struct MarketModel  <: AbstractEventStudyModel 
    market_returns::TSFrame
end

"""
"""
struct AugmentedMarketModel <: AbstractEventStudyModel 
end

"""
"""
struct ExcessReturn <: AbstractEventStudyModel 
    market_return::Real
end

"""
    ConstantMeanReturn(market_return::Real)
"""
struct ConstantMeanReturn <: AbstractEventStudyModel 
end

"""
    NoModel

A very fancy way to say that no decorrelation needs to be done.
"""
struct NoModel <: AbstractEventStudyModel end


# Define functions which take in and decorrelate TSFrames

"""
    decorrelate(returns::AbstractVector{<: Real}, model::AbstractEventStudyModel)::TSFrame

Return a 
"""
function apply_model(model::AbstractEventStudyModel, returns::TSFrame)
    error("Not implemented yet for model type $model.")
end



function apply_model(model::MarketModel, returns::TSFrame)
    # @assert index(model.market_returns) == index(returns)

    data_tsframe = TSFrames.join(
        TSFrame(DataFrame(:Index => index(model.market_returns), :market_returns => model.market_returns.coredata[!, 2]); issorted = true, copycols = false), 
        returns; 
        jointype = :JoinAll
    )

    dropmissing!(data_tsframe)

    glm(Matrix(TSFrame(data_tsframe.coredata[:, Not(:market_returns)]; copycols = false, issorted = true), data_tsframe.market_returns))
end

function apply_model(model::ExcessReturn, returns::TSFrame)
    result = deepcopy(returns)
    for column in names(result)
        result.coredata[!, column] .-= model.market_returns
    end
    return result
end


function apply_model(::ConstantMeanReturn, returns::TSFrame)
    result = deepcopy(returns)
    for column in names(result)
        result.coredata[!, column] .-= mean(result.coredata[!, column])
    end
    return result
end