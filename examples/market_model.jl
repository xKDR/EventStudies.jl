using TSFrames
using MarketData
using Dates
using DataFrames
using EventStudies
using GLM

nifty = TSFrame(MarketData.yahoo("^NSEI"))
select!(nifty.coredata, :Index, :AdjClose => :NIFTY)
dropmissing!(nifty.coredata)

nifty_stocks = [
    "RELIANCE.NS",
    "HDFCBANK.NS",
    "INFY.NS",
    "ICICIBANK.NS",
    "TCS.NS",
    "ITC.NS",
    "KOTAKBANK.NS",
    "LT.NS",
    "HINDUNILVR.NS",
    "AXISBANK.NS",
]

nifty_ticker_ts = TSFrame.(MarketData.yahoo.(nifty_stocks))

for (i, ts) in enumerate(nifty_ticker_ts)
    select!(ts.coredata, :Index, :AdjClose => Symbol(nifty_stocks[i]))
end

nifty_ticker_ts
dropmissing!.(getproperty.(nifty_ticker_ts, :coredata))

nifty_ticker_levels_ts = TSFrames.join(levels_to_returns.(nifty_ticker_ts)...; jointype = :JoinAll)
nifty_levels = levels_to_returns(nifty)


function EventStudies.apply_model(model::MarketModel, data::TSFrame; strict::Bool = true)
    # merge the market data with the provided data
    merged_market_ts = TSFrames.join(model.market_returns, data; jointype = :JoinRight)
    # if any data is missing, return blank and throw an error
    if strict && any(ismissing(merged_market_ts.coredata))
        return TSFrame([]), ModelDataMissing()
    end
    # drop all missing data
    dropmissing!(merged_market_ts.coredata)
    # create a TSFrame to hold the results
    return_ts = TSFrame(DataFrame(:Index => index(merged_market_ts)); issorted = true, copycols = false)
    # the independent variable should be a matrix, 
    # so we reshape the market_return vector into a matrix
    market_return_data = reshape(merged_market_ts.coredata[!, first(names(model.market_returns))], length(merged_market_ts), 1)
    # loop through all columns in `data`, and apply the model to each of them
    for colname in names(data)
        # fit a linear model
        model = GLM.lm(
            market_return_data,
            merged_market_ts.coredata[!, colname]
        )
        # add the results to the return TSFrame
        return_ts.coredata[!, colname] = predict(model)
    end
    # return the TSFrame and the event status
    return return_ts, EventStudies.Success()
end

ret, suc = EventStudies.apply_model(MarketModel(nifty_levels), nifty_ticker_levels_ts)

plot_ts = TSFrames.join(ret, nifty_levels; jointype = :JoinLeft)

EventStudies.remap_levels(remap_cumsum(plot_ts))

linecolors = Makie.PlotUtils.distinguishable_colors(11)
f = Figure()
a = Axis(f[1, 1])
i = 10
for colname in names(plot_ts)
    lines!(a, Dates.value.(index(plot_ts)), plot_ts.coredata[!, colname] .- i; color = linecolors[i ÷ 10],  label = string(colname))
    i += 10
end
Legend(f[1, 2], a)
# lines(plot_ts.Index .|> Dates.value, )
f


phystime_returns_ts, event_status = EventStudies.to_eventtime_windowed(nifty_ticker_levels_ts, [Symbol("RELIANCE.NS") => Date(2007, 12, 31)], 7, MarketModel(nifty_levels))
t0, lower, upper = inference(BootstrapInference(), phystime_returns_ts)

return_ts = TSFrame[]

@time for (stock_ts, colname) in zip(levels_to_returns.(nifty_ticker_ts), nifty_stocks)
    merged_nifty = TSFrames.join(nifty_levels, stock_ts; jointype = :JoinAll)
    dropmissing!(merged_nifty.coredata)
    model = GLM.lm(
        reshape(merged_nifty.coredata[!, :NIFTY], length(merged_nifty), 1),
        merged_nifty.coredata[!, colname]
    )
    push!(return_ts, TSFrame(predict(model), index(merged_nifty)))
end

DataFrames.rename!.(getproperty.(return_ts, :coredata), :x1 .=> Symbol.(nifty_stocks))


model = lm(reshape(merged_nifty.NIFTY, length(merged_nifty.NIFTY), 1), merged_nifty.var"RELIANCE.NS")

xs = Dates.value.(merged_nifty.Index .- merged_nifty.Index[1])
f, a, p = lines(xs, merged_nifty.NIFTY; label = "NIFTY")
lines!(a, xs, merged_nifty.var"RELIANCE.NS"; label = "RELIANCE.NS")
lines!(a, xs, predict(model); label = "Model prediction")
axislegend(a; position = :lt)
f