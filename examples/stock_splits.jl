using RData, CSV
using DataFrames, TSFrames
using EventStudies

splits_df = RData.load("/Users/anshul/Documents/Business/India/XKDR/code/eventstudies/data/SplitDates.rda")["SplitDates"]
prices_df = CSV.read(joinpath(dirname(@__DIR__), "assets", "spr.csv"), DataFrame; missingstring = "NA")

prices_ts = TSFrame(prices_df)

splits_pairs = Symbol.(splits_df.name) .=> splits_df.when

phystime_returns_ts, statuses = to_eventtime_windowed(prices_ts, splits_pairs, 5)

phystime_cum_ts = remap_cumsum(phystime_returns_ts)

t0, lower, upper = inference(BootstrapInference(; replicates = 1000), phystime_cum_ts)

f, a, p = band((1:length(lower)) .- length(lower)÷2, lower, upper)
lines!(a, (1:length(lower)) .- length(lower)÷2, t0)
f