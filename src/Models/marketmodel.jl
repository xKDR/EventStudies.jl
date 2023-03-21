
struct MyMarketModel# <: AbstractModel
    market_returns::TSFrame
end

struct MyMarketModelResult# <: AbstractModel
    model::MyMarketModel
    alpha::Float64
    beta::Float64
end

function GLM.StatsBase.fit(model::MyMarketModel, data::TSFrame; debug = false)
    # merge the market data with the provided data
    merged_market_ts = TSFrames.join(model.market_returns, data; jointype = :JoinRight)
    # the independent variable should be a matrix, 
    # so we reshape the market_return vector into a matrix
    market_return_data = hcat(ones(size(merged_market_ts.coredata, 1)), merged_market_ts.coredata[!, 2])
    # loop through all columns in `data`, and apply the model to each of them
    linear_model = GLM.lm(
        GLM.Term(Symbol(first(names(data)))) ~ GLM.Term(Symbol(first(names(model_market_returns)))),
        merged_market_ts.coredata[!, 2:end]
    )
    ct = GLM.coeftable(linear_model)
    α, β = ct.cols[1]
    return MyMarketModelResult(model, α, β)
end


function apply(result::MyMarketModelResult, data::TSFrame)
    ret = deepcopy(data)
    market_data = TSFrame(TSFrames.DataFrames.leftjoin(data.coredata, model.market_returns.coredata; on = :Index))#TSFrames.join(data, model.market_returns; jointype = :JoinRight)
    for col in names(data)
        ret.coredata[!, col] = data.coredata[!, col] .- result.alpha .- result.beta .* market_data.coredata[!, first(names(model.market_returns))]
    end
    return ret
end

# model = MyMarketModel(nifty_returns)
# result = GLM.StatsBase.fit(model, data)
# ret = apply(result, TSFrame(data.coredata[5000:end, :]))

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
