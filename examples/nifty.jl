using Pkg
Pkg.add("TSFrames")
Pkg.add("DataFrames")
Pkg.add("CSV")
Pkg.add("MarketData")
Pkg.add(; url = "https://github.com/asinghvi17/EventStudies.jl", rev = "as/eventstudies")


## Load the packages:
using TSFrames
using MarketData
using Dates
using DataFrames
using EventStudies
## Hindenberg report 24 Jan

# nifty stock price data
nifty = TSFrame(MarketData.yahoo("^NSEI"))
select!(nifty.coredata, :Index, :AdjClose => :NIFTY)
#USD/INR
usd_inr = TSFrame(MarketData.yahoo("USDINR=X"))
select!(usd_inr.coredata, :Index, :AdjClose => :USDINR)

# US Fed funds rate
fed_rate = TSFrame(MarketData.fred("FEDFUNDS"))
fed_rate = TSFrame(fed_rate.coredata[searchsortedfirst(index(fed_rate), Date(2007, 1, 1)):end, :])
fed_rate_diffs = diff(fed_rate)
dropmissing!(fed_rate_diffs.coredata)
fed_rate_dates = filter(:VALUE => >(0), fed_rate_diffs.coredata)

############################################################
#                          Nifty                           #
############################################################

phystime_returns_ts, event_status = EventStudies.to_eventtime_windowed(levels_to_returns(nifty), (:NIFTY,) .=> fed_rate_dates.Index, 7)
t0, lower, upper = inference(BootstrapInference(), phystime_returns_ts)

N = 100
xs = (phystime_returns_ts.Index .|> Dates.value) .+ 365
deviations = LinRange(0.5, 0.975, N÷2)

x_vals = permutedims(hcat(fill(xs, N)...))
y_vals = zeros(N, length(xs))
y_colors = zeros(N, length(xs))

for (y_ind, deviation) in enumerate(deviations)
    t0, lower, upper = inference(BootstrapInference(), phystime_returns_ts, deviation)
    y_vals[50 - y_ind + 1, :] .= lower
    y_vals[50 + y_ind , :] .= upper
    y_colors[50 - y_ind + 1, :] .= 1 - deviation
    y_colors[50 + y_ind , :] .= deviation
    
end

# plot
f, a, p = lines((phystime_returns_ts.Index .|> Dates.value) .+ 365, t0; label = "Mean over all events")
sp = surface!(a, x_vals, y_vals, y_colors; shading = false, colormap = :diverging_bwr_55_98_c37_n256)
translate!(p, 0,0,1)
f
p.color = Makie.wong_colors()[3]
f

Colorbar(f[1, 2], sp; label = "Confidence level")
axislegend(a; position = :rt)

a.title = "Nifty performance after a Fed rate hike"
a.subtitle = rich(rich("t=0", font = to_font("Fira Mono")), " indicates the time of rate hike")
a.titlealign = :left
a.xlabel = "Event time (days)"
a.ylabel = "NIFTY returns"
a.xticks = WilkinsonTicks(8; k_min = 5, k_max = 10)

f

save("nifty.pdf", f; pt_per_unit = 1)


############################################################
#                          USDINR                          #
############################################################


phystime_returns_ts, event_status = EventStudies.to_eventtime_windowed(levels_to_returns(usd_inr), (:USDINR,) .=> fed_rate_dates.Index, 7)
t0, lower, upper = inference(BootstrapInference(), phystime_returns_ts)

N = 100
xs = (phystime_returns_ts.Index .|> Dates.value) .+ 365
deviations = LinRange(0.5, 0.975, N÷2)

x_vals = permutedims(hcat(fill(xs, N)...))
y_vals = zeros(N, length(xs))
y_colors = zeros(N, length(xs))

for (y_ind, deviation) in enumerate(deviations)
    t0, lower, upper = inference(BootstrapInference(), phystime_returns_ts, deviation)
    y_vals[50 - y_ind + 1, :] .= lower
    y_vals[50 + y_ind , :] .= upper
    y_colors[50 - y_ind + 1, :] .= 1 - deviation
    y_colors[50 + y_ind , :] .= deviation
    
end

# plot
f, a, p = lines((phystime_returns_ts.Index .|> Dates.value) .+ 365, t0; label = "Mean over all events")
sp = surface!(a, x_vals, y_vals, y_colors; shading = false, colormap = :diverging_bwr_55_98_c37_n256)
translate!(p, 0,0,1)
f
p.color = Makie.wong_colors()[3]
f

Colorbar(f[1, 2], sp; label = "Confidence level")
axislegend(a; position = :rt)

a.title = "USD-INR performance after a Fed rate hike"
a.subtitle = rich(rich("t=0", font = to_font("Fira Mono")), " indicates the time of rate hike")
a.titlealign = :left
a.xlabel = "Event time (days)"
a.ylabel = "USD-INR returns"
a.xticks = WilkinsonTicks(8; k_min = 5, k_max = 10)
f



save("usdinr.pdf", f; pt_per_unit = 1)