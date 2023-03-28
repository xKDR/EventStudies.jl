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
select!(nifty.coredata, :Index, :AdjClose => :NIFTY)

# USD/INR exchange rate
usd_inr = TSFrame(MarketData.yahoo("USDINR=X"))
select!(usd_inr.coredata, :Index, :AdjClose => :USDINR)

# US Fed funds rate
fed_rate = TSFrame(MarketData.fred("FEDFUNDS"))
fed_rate_2007 = TSFrame(fed_rate.coredata[searchsortedfirst(index(fed_rate), Date(2007, 1, 1)):end, :])
fed_rate_diffs = diff(fed_rate_2007)
dropmissing!(fed_rate_diffs.coredata)
fed_rate_dates = filter(:VALUE => >(0), fed_rate_diffs.coredata)

############################################################
#                          Nifty                           #
############################################################

phystime_returns_ts, event_status = EventStudies.eventstudy(levels_to_returns(nifty), (:NIFTY,) .=> fed_rate_dates.Index, -6:7, #=MarketModel(levels_to_returns(fed_rate))=#)
t0, lower, upper = inference(BootstrapInference(), phystime_returns_ts)
N = 200
times = (phystime_returns_ts.Index .|> Dates.value) .+ 365
y_vals, y_colors = EventStudies.inference_surface(BootstrapInference(), phystime_returns_ts; density = N)

# plot
f, a, p = lines(times, t0; label = "Mean over all events")
sp = surface!(a, permutedims(reduce(hcat, fill(times, N))), y_vals, y_colors; shading = false, colormap = :diverging_bwr_55_98_c37_n256)
translate!(p, 0,0,-99)
translate!(sp, 0,0,-100)
f
p.color = Makie.wong_colors()[3]
f


cb = Colorbar(f[1, 2], sp; label = "Confidence level")
cb.ticks = WilkinsonTicks(8; k_min = 5, k_max = 10)
leg = axislegend(a; position = :rt)

a.title = "Nifty performance after a Fed rate hike"
a.subtitle = rich(rich("t=0", font = to_font("Fira Mono")), " indicates the time of rate hike")
a.titlealign = :left
a.xlabel = "Event time (days)"
a.ylabel = "NIFTY returns"
a.xticks = WilkinsonTicks(8; k_min = 5, k_max = 10)

f

# save("nifty.pdf", f; pt_per_unit = 1)


############################################################
#                          USDINR                          #
############################################################


phystime_returns_ts, event_status = EventStudies.eventstudy(levels_to_returns(usd_inr), (:USDINR,) .=> fed_rate_dates.Index, -6:7)
t0, lower, upper = inference(BootstrapInference(), phystime_returns_ts)

phystime_returns_ts = remap_cumsum(phystime_returns_ts)

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

cb = Colorbar(f[1, 2], sp; label = "Confidence level")
cb.ticks = WilkinsonTicks(8; k_min = 5, k_max = 10)
leg = axislegend(a; position = :rt)

a.title = "USD-INR performance after a Fed rate hike"
a.subtitle = rich(rich("t=0", font = to_font("Fira Mono")), " indicates the time of rate hike")
a.titlealign = :left
a.xlabel = "Event time (days)"
a.ylabel = "USD-INR returns"
a.xticks = WilkinsonTicks(8; k_min = 5, k_max = 10)
f



# save("usdinr_2.pdf", f; pt_per_unit = 1)