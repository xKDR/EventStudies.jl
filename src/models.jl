# # Define event study decorrelation models
# """
# """
# abstract type AbstractEventStudyModel end

# """
#     MarketModel(market_returns::TSFrame)

# Regresses "market" returns on the variable using a linear model.

# """
# struct MarketModel <: AbstractEventStudyModel 
#     market_returns::TSFrame
# end

# """
#     AugmentedMarketModel(market_returns::TSFrame, additional_returns::TSFrame)

# Applies the augmented market model of eventstudy.R to the data.  
# """
# struct AugmentedMarketModel <: AbstractEventStudyModel 
# end

# """
#     ExcessReturn(market_returns::TSFrame)

# This models basic scalar excess return.  
# """
# struct ExcessReturn <: AbstractEventStudyModel 
#     market_returns::TSFrame
# end

# """
#     ConstantMeanReturn()

# Each column is decreased by its mean.
# """
# struct ConstantMeanReturn <: AbstractEventStudyModel 
# end

# """
#     NoModel()

# A very fancy way to say that no decorrelation needs to be done.  No-op.
# """
# struct NoModel <: AbstractEventStudyModel end


# # Define functions which apply these models to `TSFrame`s

# # main entry point:
# function apply_model(model::AbstractEventStudyModel, data::TSFrame, window)
#     apply_model(model, data)
# end

# # this is a method stub, which errors if the method hasn't been implemented yet.
# """
#     apply_model(model::AbstractEventStudyModel, data::TSFrame)::(::TSFrame, ::EventStatus)

# Applies the given `model` to the provided `TSFrame`, 
# and returns a `TSFrame` (may be empty) along with an [`EventStatus`](@ref) code.  
# If the [`EventStatus`](@ref) code is not `Success()`, then the returned `TSFrame` should (and will) be ignored.
# """
# function apply_model(model::AbstractEventStudyModel, data::TSFrame)
#     error("Not implemented yet for model type $model.")
#     # return result_tsframe::TSFrame, success_code::EventStatus
# end

# # TODO: this interface is actually incorrect...what we need to do, 
# # is allow the user to pass separate window and estimation periods.
# # then we can window.
# # so, the interface could be:
# # apply_model(model::AbstractEventStudyModel, data::TSFrame, window::Any)::(::TSFrame, ::EventStatus)
# # where data is a TSFrame (TSFrameView?) and we return a windowed TSFrame
# # problems: implementing checks for all the different possible error states
# # when windowing
# # but, if we check earlier, we have to allocate 2 vectors, which is inefficient.


# # Market model implementation

# # to note for the future:
# # julia> @macroexpand @formula(a ~ b)
# # :(StatsModels.Term(:a) ~ StatsModels.Term(:b))
# # julia> StatsModels.Term(colname) ~ StatsModels.Term(:b)
# # FormulaTerm
# # Response:
# #   a(unknown)
# # Predictors:
# #   b(unknown)

# # julia> @formula(a ~ b)
# # FormulaTerm
# # Response:
# #   a(unknown)
# # Predictors:
# #   b(unknown)

# # so you can just use StatsModels.Term in place of `@formula`, IF you don't need fancy packaging.
# function apply_model(model::MarketModel, data::TSFrame, window; strict::Bool = true)
    # # merge the market data with the provided data
    # merged_market_ts = TSFrames.join(model.market_returns, data; jointype = :JoinRight)
    # # if any data is missing, return blank and throw an error
    # if strict && any(ismissing(merged_market_ts.coredata))
    #     return TSFrame([]), ModelDataMissing()
    # end
    # # drop all missing data, of which there is presumably none
    # dropmissing!(merged_market_ts.coredata)
    # # create a TSFrame to hold the results
    # return_ts = TSFrame(DataFrame(:Index => index(merged_market_ts)); issorted = true, copycols = false)
    # # the independent variable should be a matrix, 
    # # so we reshape the market_return vector into a matrix
    # market_return_data = reshape(merged_market_ts.coredata[!, first(names(model.market_returns))], length(merged_market_ts), 1)
    # # loop through all columns in `data`, and apply the model to each of them
    # for colname in names(data)
    #     # fit a linear model
    #     model = GLM.lm(
    #         market_return_data,
    #         merged_market_ts.coredata[!, colname]
    #     )
    #     # add the results to the return TSFrame
    #     # here, we take the residuals and not the prediction
    #     return_ts.coredata[!, colname] = residuals(model)
    # end
    # # return the TSFrame and the event status
    # return return_ts, EventStudies.Success()
# end

# # Excess return implementation

# function apply_model(model::ExcessReturn, data::TSFrame)
#     # merge the market data with the provided data
#     merged_market_ts = TSFrames.join(
#         TSFrame(DataFrame(:Index => index(model.market_returns), :market_returns => model.market_returns.coredata[!, 2]); issorted = true, copycols = false), 
#         data; 
#         jointype = :JoinRight
#     )
#     # if any data is missing, return blank and throw an error
#     if strict && any(ismissing(merged_market_ts.coredata))
#         return TSFrame([]), ModelDataMissing()
#     end
#     # drop all missing data
#     dropmissing!(merged_market_ts.coredata)
#     for column in names(data)
#         merged_market_ts.coredata[!, column] .-= merged_market_ts.market_returns
#     end
#     return (TSFrame(select!(merged_market_ts.coredata, Not(:market_returns)); copycols = false, issorted = false), Success())
# end

# # Constant mean return implementation

# function apply_model(::ConstantMeanReturn, data::TSFrame)
#     result = deepcopy(data)
#     for column in names(result)
#         result.coredata[!, column] .-= mean(result.coredata[!, column])
#     end
#     return (result, Success())
# end

# # No-op for `NoModel`

# function apply_model(::NoModel, data::TSFrame)
#     return (data, Success())
# end

# eventstudy(...; model = )

# model = MarketModel(market_data)
# result::MarketModelResult = fit(model, bhel_data)
# apply_model(MarketModelResult(...), bhel_data)

# # Github Copilot's hallucinations

# # so, maybe the best is to just make the user pass a windowed TSFrame.
# # then, we can just check for missing data.
# # and, if the user doesn't want to window, they can just pass the whole TSFrame.
# # and, if they want to window, they can just pass a TSFrameView.
# # so, we just need to make sure that the TSFrameView is allowed to be passed to TSFrames.join
# # and, if not, we can just use TSFrames.subset to get a TSFrame from it.
# # so, the interface is:
