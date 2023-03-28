using RData, CodecXz

using EventStudies, TSFrames, Dates, MarketData
using CairoMakie

# ## Stock splits

# Stock split data from eventstudies.r
# TODO: This has a couple of events with missings, which es.R doesn't have
# We have to debug this
stock_returns = EventStudies.zoo_to_tsframe(RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/StockPriceReturns.rda"; convert = false)["StockPriceReturns"])
split_dates_df = RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/SplitDates.rda"; convert = true)["SplitDates"]
# other_returns = EventStudies.zoo_to_tsframe(RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/OtherReturns.rda"; convert = false)["OtherReturns"])
nifty = TSFrame(MarketData.yahoo("^NSEI"))
select!(nifty.coredata, :Index, :AdjClose => :NIFTY)
nifty_returns = EventStudies.levels_to_returns(nifty)

eventtime_ts, event_return_codes = eventstudy(stock_returns, Symbol.(split_dates_df.name) .=> split_dates_df.when, -6:7, MarketModel(nifty_returns))

t0, lower, upper = EventStudies.inference(BootstrapInference(), eventtime_ts[:, [3, 4, 6, 7]])

lines(t0)
lines!(lower)
lines!(upper)
Makie.current_figure()

# ## Terrorism

# ## Something else