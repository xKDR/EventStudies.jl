
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
    ExcessReturn(market_returns::TSFrame)

This models basic scalar excess return.  
"""
struct ExcessReturn <: AbstractEventStudyModel 
    market_returns::TSFrame
end

"""
    ConstantMeanReturn()

Each column is decreased by its mean.
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
    apply_model(model::AbstractEventStudyModel, data::TSFrame)::(::TSFrame, ::EventStatus)

Applies the given `model` to the provided `TSFrame`, 
and returns a `TSFrame` (may be empty) along with an [`EventStatus`](@ref) code.  
If the [`EventStatus`](@ref) code is not `Success()`, then the returned `TSFrame` should (and will) be ignored.
"""
function apply_model(model::AbstractEventStudyModel, data::TSFrame)
    error("Not implemented yet for model type $model.")
    # return result_tsframe::TSFrame, success_code::EventStatus
end



function apply_model(model::MarketModel, returns::TSFrame)
    # @assert index(model.market_returns) == index(returns)

    data_tsframe = TSFrames.join(
        TSFrame(DataFrame(:Index => index(model.market_returns), :market_returns => model.market_returns.coredata[!, 2]); issorted = true, copycols = false), 
        returns; 
        jointype = :JoinRight
    )
    # Drop all missing data
    dropmissing!(data_tsframe)
    # Fit a generalized linear model
    glm(Matrix(TSFrame(data_tsframe.coredata[:, Not(:market_returns)]; copycols = false, issorted = true), data_tsframe.market_returns))
end

function apply_model(model::ExcessReturn, returns::TSFrame)
    data_tsframe = TSFrames.join(
        TSFrame(DataFrame(:Index => index(model.market_returns), :market_returns => model.market_returns.coredata[!, 2]); issorted = true, copycols = false), 
        returns; 
        jointype = :JoinRight
    )
    for column in names(returns)
        data_tsframe.coredata[!, column] .-= data_tsframe.market_returns
    end
    return (TSFrame(select!(data_tsframe.coredata, Not(:market_returns)); copycols = false, issorted = false), Success())
end


function apply_model(::ConstantMeanReturn, returns::TSFrame)
    result = deepcopy(returns)
    for column in names(result)
        result.coredata[!, column] .-= mean(result.coredata[!, column])
    end
    return (result, Success())
end

function apply_model(model::NoModel, returns::TSFrame)
    return (returns, Success())
end