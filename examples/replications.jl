using RData, CodecXz

using EventStudies, TSFrames, DataFrames, Dates, MarketData
using CairoMakie

# ## Stock splits

# First, we'll load the stock split data from eventstudies.R.
stock_returns = EventStudies.zoo_to_tsframe(RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/StockPriceReturns.rda"; convert = false)["StockPriceReturns"])
split_dates_df = RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/SplitDates.rda"; convert = true)["SplitDates"]
other_returns = EventStudies.zoo_to_tsframe(RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/OtherReturns.rda"; convert = false)["OtherReturns"])

# ### No model
# Let's try a regular event study, with no model:

eventtime_ts, event_return_codes = eventstudy(
    stock_returns, # returns TSFrame
    Symbol.(split_dates_df.name) .=> split_dates_df.when, # [:colname => event_time, ...]
    -6:7 # window - asymmetric to completely mimic R
    ) # note that we haven't provided a model, so it defaults to `nothing` (no-op).

# Now, let's perform bootstrap inference:

t0, lower, upper = EventStudies.inference(BootstrapInference(), eventtime_ts |> EventStudies.remap_cumsum)

# and plot the results!

scatterlines(-6:7, t0; label = "Mean")
lines!(-6:7, upper; color = Makie.wong_colors(0.5)[1], linestyle = :dash, label = "95% CI")
lines!(-6:7, lower; color = Makie.wong_colors(0.5)[1], linestyle = :dash)
## spruce up the figure
axislegend(Makie.current_axis(); position = :lt)
Makie.current_axis().xlabel = "Event time (days)"
Makie.current_axis().ylabel = "Return (%)"
Makie.current_axis().title = "Event study of stock splits"
Makie.current_axis().titlealign = :left
Makie.current_axis().subtitle = "In the Indian market, with the NIFTY index applied as a market model"
translate!(Makie.current_axis().scene.plots[1], 0, 0, 1)
Makie.current_figure()

# ### Market model (NIFTY)


eventtime_ts, event_return_codes = eventstudy(
    stock_returns, # same as before
    Symbol.(split_dates_df.name) .=> split_dates_df.when, # same as before
    -6:7, # same as before
    MarketModel(other_returns[:, [:NiftyIndex]]) # ooh, what's this?
    )

# Now for the inference:

t0, lower, upper = EventStudies.inference(BootstrapInference(), eventtime_ts |> EventStudies.remap_cumsum)

# and the plots!

scatterlines(-6:7, t0; label = "Mean")
lines!(-6:7, upper; color = Makie.wong_colors(0.5)[1], linestyle = :dash, label = "95% CI")
lines!(-6:7, lower; color = Makie.wong_colors(0.5)[1], linestyle = :dash)
## spruce up the figure
axislegend(Makie.current_axis(); position = :lt)
Makie.current_axis().xlabel = "Event time (days)"
Makie.current_axis().ylabel = "Return (%)"
Makie.current_axis().title = "Event study of stock splits"
Makie.current_axis().titlealign = :left
Makie.current_axis().subtitle = "In the Indian market, with the NIFTY index applied as a market model"
translate!(Makie.current_axis().scene.plots[1], 0, 0, 1)
Makie.current_figure()

# Note how this looks subtly different than the first plot, just because of the market model!

# ## Intraday data

aggregate_returns = EventStudies.zoo_to_tsframe(RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/AggregateReturns.rda"; convert = false)["AggregateReturns"])
rate_cuts_df = RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/RateCuts.rda"; convert = true)["RateCuts"]
index_returns = EventStudies.zoo_to_tsframe(RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/IndexReturns.rda"; convert = false)["IndexReturns"])

intraday_eventtime_ts, event_return_codes = eventstudy(
    aggregate_returns,
    Symbol.(rate_cuts_df.name) .=> rate_cuts_df.when,
    -34:35,
    MarketModel(index_returns[:, [:x_1]])
    )

intraday_eventtime_ts.coredata[1, :] .= 0

t0, lower, upper = EventStudies.inference(BootstrapInference(), intraday_eventtime_ts |> EventStudies.remap_cumsum)



# ## Something else

