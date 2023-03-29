# # The effect of Fed rate hikes on Indian indicators


## Load the packages:
using TSFrames
using MarketData
using Dates
using DataFrames
using EventStudies
using CairoMakie

# First, get data about stock prices from MarketData.jl:

# NIFTY index (India)
nifty = TSFrame(MarketData.yahoo("^NSEI"))
select!(nifty.coredata, :Index, :AdjClose => :NIFTY);
nifty # hide

# USD/INR exchange rate
usd_inr = TSFrame(MarketData.yahoo("USDINR=X"))
select!(usd_inr.coredata, :Index, :AdjClose => :USDINR);
usd_inr # hide

# US Fed funds rate
fed_rate = TSFrame(MarketData.fred("FEDFUNDS"))
fed_rate_2007 = TSFrame(fed_rate.coredata[searchsortedfirst(index(fed_rate), Date(2007, 1, 1)):end, :])
fed_rate_diffs = diff(fed_rate_2007)
dropmissing!(fed_rate_diffs.coredata)
fed_rate_dates = filter(:VALUE => >(0), fed_rate_diffs.coredata)

# Then, we perform the event studies!

# ## NIFTY

eventtime_returns_ts, event_status = EventStudies.eventstudy(
    levels_to_returns(nifty), 
    (:NIFTY,) .=> fed_rate_dates.Index, 
    -6:7
    )

eventtime_cumulative_ts = remap_cumsum(eventtime_returns_ts)
t0, lower, upper = inference(BootstrapInference(), eventtime_cumulative_ts)

eventtime_cumulative_ts

# plot the result

f, a, p = scatterlines(index(eventtime_cumulative_ts), t0; label = "Mean over all events")
p2 = band!(a, index(eventtime_cumulative_ts), lower, upper; label = "95% CI")
translate!(p, 0, 0, 1) # bring the scatterlines to the front

leg = axislegend(a; position = :rt)

a.title = "NIFTY index performance after a Fed rate hike"
a.subtitle = rich(rich("t=0", font = to_font("Fira Mono")), " indicates the time of rate hike")
a.titlealign = :left
a.xlabel = "Event time (days)"
a.ylabel = "NIFTY returns (%)"
a.xticks = WilkinsonTicks(8; k_min = 5, k_max = 10)
f


# save("nifty.pdf", f; pt_per_unit = 1)


# ## USD/INR


eventtime_returns_ts, event_status = EventStudies.eventstudy(levels_to_returns(usd_inr), (:USDINR,) .=> fed_rate_dates.Index, -6:7)

eventtime_cumulative_ts = remap_cumsum(eventtime_returns_ts)
t0, lower, upper = inference(BootstrapInference(), eventtime_cumulative_ts)

eventtime_cumulative_ts

# plot the result

f, a, p = scatterlines(index(eventtime_cumulative_ts), t0; label = "Mean over all events")
p2 = band!(a, index(eventtime_cumulative_ts), lower, upper; label = "95% CI")
translate!(p, 0, 0, 1) # bring the scatterlines to the front

leg = axislegend(a; position = :rt)

a.title = "USD-INR performance after a Fed rate hike"
a.subtitle = rich(rich("t=0", font = to_font("Fira Mono")), " indicates the time of rate hike")
a.titlealign = :left
a.xlabel = "Event time (days)"
a.ylabel = "USD-INR returns (%)"
a.xticks = WilkinsonTicks(8; k_min = 5, k_max = 10)
f



# save("usdinr_2.pdf", f; pt_per_unit = 1)