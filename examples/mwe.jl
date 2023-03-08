using TSFrames
using EventStudies
using Makie

# first, define the TSFrame
ts1 = TSFrame(
    DataFrame(
        :Index => 1:11,
        :var1 => vcat(LinRange(0, 1, 5), ones(6)),
        :var2 => vcat(LinRange(0, 1, 6), ones(5)),
    )
)

# For convenience, I've directly referred to everything from EventStudies.jl as `EventStudies.*`.
# However, these are all exported, so you don't have to do that.

phystime_returns_ts, statuses = EventStudies.to_eventtime_windowed(levels_to_returns(ts1), [:var1 => 5, :var2 => 6], 2)
phystime_cum_ts = EventStudies.remap_cumsum(phystime_returns_ts)
confints = EventStudies.inference(EventStudies.BootstrapInference(), phystime_cum_ts)

f, a, p = series(phystime_cum_ts.Index, Matrix(phystime_cum_ts)'; axis = (xlabel = "Time relative to event", ylabel = "Cumulative difference (%)"))
band!(phystime_cum_ts.Index, confints[2], confints[3])
lines!(phystime_cum_ts.Index, confints[1])
Makie.current_figure()

