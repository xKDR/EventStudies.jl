# # The effect of legislation on sex ratio at birth

# This is an example of using EventStudies on long-form data from social sciences.  Specifically, we're going to be using data which 

## Load the packages:
using TSFrames         # time series package - EventStudies only accepts this, since it has a defined index type
using EventStudies     # event study package
using DataFrames       # data manipulation
using CairoMakie       # plotting

# Load the data.
data = EventStudies.load_data("bigdata.csv")

# This data is in "long" format, so we need to convert it to "wide" format.

# We do this by grouping by country,
country_data = groupby(data, :country)
# filtering to only include countries with events defined,
countries_with_events = filter(sdf -> !(all(ismissing.(sdf.intyear_es))), country_data)
# and finally, creating a TSFrame with the `sex_rat` variable for each country.
relevant_country_ts = TSFrames.join((TSFrame(DataFrame([:Index => sdf.year_es, Symbol(sdf.country[1]) => sdf.sex_rat])) for sdf in countries_with_events)...; jointype = :inner)
# Create a mapping from country to event time, for each event.

# Note that this can have multiple events per country.
event_times = [Symbol(sdf.country[1]) => sdf.intyear_es[findfirst(!ismissing, sdf.intyear_es)] for sdf in countries_with_events]
# Convert to event time using EventStudies.jl (perform the event study).
eventtime_ts, retcodes = EventStudies.eventstudy(levels_to_returns(relevant_country_ts), event_times, 4)
# Perform bootstrap inference with a 95% confidence interval
t0, lower, upper = inference(BootstrapInference(), eventtime_ts, 0.95)
# we're technically done with the event study here!

# now, it's time to plot
# plot each variable in the event study
fig, ax, plt = series(
    index(eventtime_ts), Matrix(remap_cumsum(eventtime_ts))'; 
    labels = names(eventtime_ts), 
    color = Makie.resample_cmap(:rainbow_bgyrm_35_85_c71_n256, 15), 
    linewidth = 3,
    axis = (
        xlabel = "Years relative to event",
        xticks = WilkinsonTicks(8, k_min = 8, k_max = 8),
        ylabel = "Cumulative change\nin sex ratio (%)",
        title = "Variable: sex ratio at birth",
        subtitle = "Event: some legislation",
        titlealign = :left,
    ),
    figure = (resolution = (1000, 1000),)
)
leg = Legend(fig[2, 1], ax; nbanks = 3, tellwidth = false, tellheight = true)
fig


# plot inference
fig, ax, mean_plt = lines(
    index(eventtime_ts), t0; 
    label = "Mean", 
    linewidth = 3,
    axis = (
        xlabel = "Years relative to event",
        xticks = WilkinsonTicks(8, k_min = 8, k_max = 8),
        ylabel = "Cumulative change\nin sex ratio (%)",
        title = "Variable: sex ratio at birth",
        subtitle = "Event: some legislation",
        titlealign = :left,
    ),
)

band_plt = band!(ax,
    index(eventtime_ts), lower, upper; 
    label = "95% CI", 
    linewidth = 3,
    color = Makie.wong_colors(0.5)[2],
)

leg = axislegend(ax, position = :lt)

fig

# plot inference using errorbars
fig, ax, plt = rangebars(
    index(eventtime_ts), 
    lower, upper;
    whiskerwidth = 16,
    label = "95% CI",
    axis = (
        xlabel = "Years relative to event",
        xticks = WilkinsonTicks(8, k_min = 8, k_max = 8),
        ylabel = "Cumulative change\nin sex ratio (%)",
        title = "Variable: sex ratio at birth",
        subtitle = "Event: some legislation",
        titlealign = :left,
    ),
)

scatter!(ax, index(eventtime_ts), t0; label = "Mean value")
# small hack for a feature which we should add into Makie
function Makie.legendelements(plot::Rangebars, legend)
    line_points = lift(plot.whiskerwidth) do ww
        if ww ≤ 3
            Point2f[(0.5, 1), (0.5, 0)]
        else
            Point2f[(0.25, 1), (0.75, 1), (NaN, NaN), (0.5, 1), (0.5, 0), (NaN, NaN), (0.25, 0), (0.75, 0)]
        end
    end
    return Makie.LegendElement[
        LineElement(
            points = line_points, 
            color = Makie.scalar_lift(plot.color, legend.linecolor), 
            linewidth = Makie.scalar_lift(plot.linewidth, legend.linewidth)
        ),
    ]
end

axislegend(ax, position = :lt)

fig


# replicate eventstudies.R results

# convert to event time
eventtime_ts, retcodes = EventStudies.eventstudy(levels_to_returns(relevant_country_ts), event_times, -2:3)
# perform inference with a 95% confidence interval
t0, lower, upper = inference(BootstrapInference(), eventtime_ts, 0.95)
# we're technically done with the event study here!


# plot inference
fig, ax, mean_plt = lines(
    index(eventtime_ts), t0; 
    label = "Mean", 
    linewidth = 3,
    axis = (
        xlabel = "Years relative to event",
        xticks = WilkinsonTicks(8, k_min = 8, k_max = 8),
        ylabel = "Cumulative change\nin sex ratio (%)",
        title = "Variable: sex ratio at birth",
        subtitle = "Event: some legislation",
        titlealign = :left,
    ),
)

band_plt = band!(ax,
    index(eventtime_ts), lower, upper; 
    label = "95% CI", 
    linewidth = 3,
    color = Makie.wong_colors(0.5)[2],
)

leg = axislegend(ax, position = :lt)

ylims!(ax, -0.75, 0.75) # match R
ylims!(ax, -0.5, 0.5) # match R
fig