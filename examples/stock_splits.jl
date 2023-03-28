using DataFrames, TSFrames
using EventStudies

splits_df = EventStudies.load_data("SplitDates.rda")
prices_df = CSV.read(joinpath(dirname(@__DIR__), "assets", "spr.csv"), DataFrame; missingstring = "NA")
nifty = TSFrame(MarketData.yahoo("^NSEI"))
select!(nifty.coredata, :Index, :AdjClose => :NIFTY)
dropmissing!(nifty.coredata)
nifty_ts = levels_to_returns(nifty)

prices_ts = TSFrame(prices_df)

splits_pairs = Symbol.(splits_df.name) .=> splits_df.when

phystime_returns_ts, statuses = to_eventtime_windowed(prices_ts, splits_pairs, 5, #=MarketModel(nifty_ts)=#)

phystime_cum_ts = remap_cumsum(phystime_returns_ts)

t0, lower, upper = inference(BootstrapInference(; replicates = 1000), phystime_cum_ts)

f, a, p = band((1:length(lower)) .- length(lower)/2, lower, upper)
lines!(a, (1:length(lower)) .- length(lower)/2, t0)
f


N = 200
times = (phystime_cum_ts.Index .|> Dates.value) .+ 365
y_vals, y_colors = EventStudies.inference_surface(BootstrapInference(), phystime_cum_ts; density = N)

# plot
f, a, p = lines(times, t0; label = "Mean over all events")
sp = surface!(a, permutedims(reduce(hcat, fill(times, N))), y_vals, y_colors; shading = false, colormap = :diverging_bwr_55_98_c37_n256)
translate!(p, 0,0,-1)
translate!(sp, 0,0,-2)
f
p.color = Makie.wong_colors()[3]
f


cb = Colorbar(f[1, 2], sp; label = "Confidence level")
cb.ticks = WilkinsonTicks(8; k_min = 5, k_max = 10)
leg = axislegend(a; position = :lt)

a.title = "Stock prices after a stock split"
a.subtitle = rich(rich("t=0", font = to_font("Fira Mono")), " indicates the official time of the stock split")
a.titlealign = :left
a.xlabel = "Event time (days)"
a.ylabel = "Stock cumulative returns"
a.xticks = WilkinsonTicks(8; k_min = 5, k_max = 10)


f
