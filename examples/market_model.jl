# # Using a market model with EventStudies.jl

# We load the following packages:
using TSFrames, DataFrames, MarketData
using Dates
using EventStudies
using CairoMakie # for plotting

# We load the NIFTY index from MarketData.jl:
nifty = TSFrame(MarketData.yahoo("^NSEI"))
select!(nifty.coredata, :Index, :AdjClose => :NIFTY)
dropmissing!(nifty.coredata)

# We load the following stocks from MarketData.jl:

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

nifty_ticker_tsframes = TSFrame.(MarketData.yahoo.(nifty_stocks))

# We loop through the TSFrames and select the AdjClose column for each stock, and rename it to the stock's ticker symbol.
for (name, ts) in zip(nifty_stocks, nifty_ticker_tsframes) 
    select!(ts.coredata, :Index, :AdjClose => Symbol(name))
end

dropmissing!.(getproperty.(nifty_ticker_tsframes, :coredata))

# Finally, we convert the prices to returns:
nifty_ticker_returns_tsframe = TSFrames.join(levels_to_returns.(nifty_ticker_tsframes)...; jointype = :JoinAll)
nifty_returns = levels_to_returns(nifty)

# We create a MarketModel object, which will be used to apply the market model to the stock returns:
market_model = MarketModel(nifty_returns)
data = nifty_ticker_returns_tsframe[:, [:var"RELIANCE.NS"]]
fit!(market_model, data)
ret = EventStudies.Models.apply(market_model, TSFrame(data.coredata[5000:end, :]))

f, a, p = lines(Dates.value.(index(data)[5000:end] .- Date(2015, 1, 1)), (TSFrame(data.coredata[5000:end, [:var"RELIANCE.NS"]]) |> EventStudies.remap_cumsum).var"RELIANCE.NS"; label = "RELIANCE.NS")
dmret = TSFrame(dropmissing(ret.coredata))
p2 = lines!(a, Dates.value.(index(dmret) .- Date(2015, 1, 1)), (dmret |> EventStudies.remap_cumsum).var"RELIANCE.NS"; label = "Reliance after market model")
nmnr = TSFrame(dropmissing(nifty_returns.coredata))
p2 = lines!(a, Dates.value.(index(nmnr) .- Date(2015, 1, 1)), (nmnr |> EventStudies.remap_cumsum).var"NIFTY"; label = "NIFTY index")
Makie.current_figure()
xlims!(a, 0, nothing)
f
axislegend(a, position = :rb)
a.title = "Market model on NIFTY index"
a.xlabel = "Days since 1/1/2015"
a.ylabel = "Cumulative returns (%)"
f

# We perform an eventstudy while passing this market model:
# TODO this doesn't work yet!
eventtime_return_ts, success_codes = to_eventtime_windowed(
    nifty_ticker_returns_tsframe,
    [],
    5,
    market_model,
)


