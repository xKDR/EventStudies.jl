# # A minimal example of using `EventStudies.jl`
# This is a basic example of how you can conduct an event study using `EventStudies.jl`. 
# We create and use synthetic data, show how to use the EventStudies.jl API, and plot it!

# First, we load the packages:
using TSFrames     # EventStudies operates exclusively on TSFrames
using EventStudies 
using CairoMakie        # For plotting

# ## Creating a dataset

# First, we define the TSFrame with the data we want to use.
# This is a TSFrame with 11 rows, and 2 columns, `var1` and `var2`.
# They both follow the same general path, linearly increasing to 1, then staying at 1.
ts1 = TSFrame(
    DataFrame(
        :Index => 1:11,
        :var1 => vcat(LinRange(0, 1, 5), ones(6)),
        :var2 => vcat(LinRange(0, 1, 6), ones(5)),
    )
)

# For convenience, I've directly referred to everything from EventStudies.jl as `EventStudies.*`.
# However, these are all exported, so you don't have to do that.

# ## Computing the event study
# Event studies are conceptually very simple - you take a time series and a list of events,
# and extract a window around each event.  Then, you perform inference on these measurements
# to see if the event had a statistically significant effect on the time series, and what that
# effect was.

# In order to conduct an event study, we need a list of events.  This has to be passed as a Vector of `Pair{Symbol, DateType}`.
# The first element of the pair is the name of the column in `ts1` that we want to use as the event.
# The second element is the time of the event.  This can be in any type `DateType` which TSFrames supports,
# which for now is restricted to `Int`, `Dates.Date`, and `Dates.DateTime`.
event_list = [:var1 => 5, :var2 => 6]

# Our dataset is the form of absolute measurements, `levels` in `EventStudies.jl` parlance.
# However, event studies function best when given data in the form of _returns_, which are the difference 
# between the log-transformed measurements, or `diff(log(ts))`.  So, we'll convert our data to returns using the [`EventStudies.levels_to_returns`](@ref) function.
# To do this, we'll use the [`EventStudies.to_eventtime_windowed`](@ref) function, which takes in a `TSFrame` of returns, a list of events, and a window size.

eventtime_returns_ts, statuses = EventStudies.to_eventtime_windowed(levels_to_returns(ts1), event_list, 2)

# The `eventtime_returns_ts` is a `TSFrame` with the same columns as `ts1`, but with a new index.  This index takes the form of "event time", which is the time relative to the event.
# All columns share the same index.  `statuses` represents the status of each event as a [`EventStatus`](@ref) object.  In this case, all events were successful.

# Now, we can compute the cumulative returns, and the confidence intervals using the [`EventStudies.remap_cumsum`](@ref) and [`EventStudies.inference`](@ref) functions.
# The `remap_cumsum` function takes in a `TSFrame` of returns, and returns a `TSFrame` of cumulative returns.  You can think of cumulative returns as 
# a mapping from returns back to levels, except renormalized so that everything starts at 0.
eventtime_cum_ts = EventStudies.remap_cumsum(eventtime_returns_ts)

# Finally, we conduct inference on the cumulative returns.  
# We'll use the [`EventStudies.BootstrapInference`](@ref) method, which takes in an inference method (see [`EventStudies.InferenceMethod`](@ref)) and the return timeseries.
# In this case, we use the bootstrap method of inference, which calls to [Bootstrap.jl](https://github.com/juliangehring/Bootstrap.jl).
confints = EventStudies.inference(EventStudies.BootstrapInference(), eventtime_cum_ts)

# ## Plotting
# Now, we can plot the results.  We'll use Makie.jl for this.
f, a, p = series(eventtime_cum_ts.Index, Matrix(eventtime_cum_ts)'; axis = (xlabel = "Event time", ylabel = "Cumulative return (%)"))
band!(eventtime_cum_ts.Index, confints[2], confints[3])
lines!(eventtime_cum_ts.Index, confints[1])
f

# And that's our event study!
