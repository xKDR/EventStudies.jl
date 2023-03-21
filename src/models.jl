
# Define event study decorrelation models
"""
"""
abstract type AbstractEventStudyModel end

"""
    MarketModel(market_returns::TSFrame)

Regresses "market" returns on the variable using a linear model.

"""
struct MarketModel <: AbstractEventStudyModel 
    market_returns::TSFrame
end

"""
    AugmentedMarketModel(market_returns::TSFrame, additional_returns::TSFrame)

Applies the augmented market model of eventstudy.R to the data.  
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
    NoModel()

A very fancy way to say that no decorrelation needs to be done.  No-op.
"""
struct NoModel <: AbstractEventStudyModel end


# Define functions which apply these models to `TSFrame`s

# main entry point:
function apply_model(model::AbstractEventStudyModel, data::TSFrame, full_column_data::TSFrame, window)
    apply_model(model, data)
end

# this is a method stub, which errors if the method hasn't been implemented yet.
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

# Constant mean return implementation

function apply_model(::ConstantMeanReturn, data::TSFrame)
    result = deepcopy(data)
    for column in names(result)
        result.coredata[!, column] .-= mean(result.coredata[!, column])
    end
    return (result, Success())
end

# No-op for `NoModel`

function apply_model(::NoModel, data::TSFrame)
    return (data, Success())
end






# Github Copilot's hallucinations

# so, maybe the best is to just make the user pass a windowed TSFrame.
# then, we can just check for missing data.
# and, if the user doesn't want to window, they can just pass the whole TSFrame.
# and, if they want to window, they can just pass a TSFrameView.
# so, we just need to make sure that the TSFrameView is allowed to be passed to TSFrames.join
# and, if not, we can just use TSFrames.subset to get a TSFrame from it.
# so, the interface is: