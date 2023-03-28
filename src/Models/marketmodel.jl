"""
    struct MarketModel <: AbstractModel
    MarketModel(market_returns::TSFrame)

A model which fits the firm's returns to the market returns,
using some provided index or market indicator.

Fit using `fit` or `fit!`, and apply to data using [`apply`](@ref)

# Fields
$(FIELDS)
"""
struct MarketModel <: AbstractModel
    "A TSFrame which holds the market indicator/index data."
    market_returns::TSFrame
    "The coefficients of the fit.  Set by `fit!`."
    coefs::Vector{Float64}
end

MarketModel(market_returns::TSFrame) = MarketModel(market_returns, Float64[NaN64, NaN64])

function StatsBase.fit!(model::MarketModel, data::TSFrame; debug = false)
    # merge the market data with the provided data
    merged_market_ts = TSFrames.join(model.market_returns, data; jointype = :JoinRight)
    # loop through all columns in `data`, and apply the model to each of them
    linear_model = GLM.lm(
        GLM.Term(Symbol(first(names(data)))) ~ GLM.Term(Symbol(first(names(model.market_returns)))),
        merged_market_ts.coredata[!, 2:end]
    )
    ct = GLM.coeftable(linear_model)
    α, β = ct.cols[1]
    model.coefs[1] = α
    model.coefs[2] = β
    return model
end

function StatsBase.fit(model::MarketModel, data::TSFrame; debug = false)
    new_model = MarketModel(model.market_returns)
    fit!(new_model, data; debug)
    return new_model
end


function StatsBase.predict(model::MarketModel, data::TSFrame)
    ret = deepcopy(data)
    market_data = TSFrame(TSFrames.DataFrames.leftjoin(data.coredata, model.market_returns.coredata; on = :Index))#TSFrames.join(data, model.market_returns; jointype = :JoinRight)
    for col in names(data)
        ret.coredata[!, col] = data.coredata[!, col] .- model.coefs[1] .- model.coefs[2] .* market_data.coredata[!, first(names(model.market_returns))]
    end
    return ret
end

# model = MarketModel(nifty_returns)
# GLM.StatsBase.fit!(model, data)
# ret = apply(model, TSFrame(data.coredata[5000:end, :]))

# f, a, p = lines(Dates.value.(index(data)[5000:end] .- Date(2015, 1, 1)), (TSFrame(data.coredata[5000:end, [:var"RELIANCE.NS"]]) |> EventStudies.remap_cumsum).var"RELIANCE.NS"; label = "RELIANCE.NS")
# dmret = TSFrame(dropmissing(ret.coredata))
# p2 = lines!(a, Dates.value.(index(dmret) .- Date(2015, 1, 1)), (dmret |> EventStudies.remap_cumsum).var"RELIANCE.NS"; label = "Reliance after market model")
# nmnr = TSFrame(dropmissing(nifty_returns.coredata))
# p2 = lines!(a, Dates.value.(index(nmnr) .- Date(2015, 1, 1)), (nmnr |> EventStudies.remap_cumsum).var"NIFTY"; label = "NIFTY index")
# Makie.current_figure()
# xlims!(a, 0, nothing)
# f
# axislegend(a, position = :rb)
# a.title = "Market model on NIFTY index"
# f
