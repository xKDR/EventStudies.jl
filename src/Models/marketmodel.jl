# # Creating a market model using TSFrames

# In this example, we will create a market model, and create dispatches on StatsBase functions to define how to fit and apply the model.

# First, we define the struct:

"""
    struct MarketModel <: AbstractModel
    MarketModel(market_returns::TSFrame)

A model which fits the firm's returns to the market returns,
using some provided index or market indicator.

Fit using `fit` or `fit!`, and apply to data using [`apply`](@ref)

# Fields
$(FIELDS)
"""
struct MarketModel <: AbstractModel
    "A TSFrame which holds the market indicator/index data."
    market_returns::TSFrame
    "The coefficients of the fit.  Set by `fit!`."
    coefs::Vector{Float64}
end

# This has two fields, `market_returns` which holds the market's returns (`diff(log.(price_at_close))`) 
# as a timeseries (`TSFrame`), and a vector of coefficients (in our case, this is ``\alpha`` and ``\beta``).

# You might notice that `coefs` is a vector and not a 2-tuple, which seems more efficient; however, 
# we want to be able to mutate the coefficients after construction, so we use a `Vector`, which is mutable.

# This defines a convenience constructor, to construct a model without fitting it.  
# Note that the `coefs` field is set to `NaN` by default, so that if the model is used before fitting, 
# it will return all NaNs to indicate that something is wrong.
MarketModel(market_returns::TSFrame) = MarketModel(market_returns, Float64[NaN64, NaN64])

# We define a short method to check whether a window is located within the model's market return timeseries:
function check_window(model::MarketModel, window)
    ## error if the index types are not the same
    @assert eltype(window) == eltype(index(model.market_returns)) 
    ## check if the window is within the market returns' timespan
    window_compatible = first(window) ≥ first(index(model.market_returns)) && last(window) ≤ last(index(model.market_returns)) 
    ## check if any of the market data in the window has missing values
    ## TODO: This is a hack which should have a more elegant solution - maybe passing event time and window vec directly?
    integer_first_index = searchsortedfirst(index(model.market_returns), first(window))
    integer_last_index = searchsortedlast(index(model.market_returns), last(window))
    market_data_compatible = !any(ismissing.(model.market_returns.coredata[integer_first_index:integer_last_index, 2]))
    return window_compatible & market_data_compatible
end


# Now, we move on to fitting the model.  This is simple enough, just defining an overload for `StatsBase.fit!`, which uses a linear model from GLM.jl.
function StatsBase.fit!(model::MarketModel, data::TSFrame)
    ## merge the market data with the provided data
    merged_market_ts = TSFrames.join(model.market_returns, data; jointype = :JoinRight)
    ## apply the model to the data
    linear_model = GLM.lm(
        GLM.Term(Symbol(first(names(data)))) ~ GLM.Term(Symbol(first(names(model.market_returns)))),
        merged_market_ts.coredata[!, 2:end]
    )
    ct = GLM.coeftable(linear_model)
    α, β = ct.cols[1]
    model.coefs[1] = α
    model.coefs[2] = β
    return model
end

# By using the verbose `GLM.Term(Symbol(...))` syntax, we were able to replicate the behaviour of the `@formula` macro from GLM programmatically.  
# This lets us hook in to the nice GLM machinery for fitting tables, as opposed to fitting matrices which is less nice.

# Now, we define a convenience function to fit the model, which returns a new model, rather than mutating the old one.
function StatsBase.fit(model::MarketModel, data::TSFrame)
    new_model = MarketModel(model.market_returns)
    fit!(new_model, data)
    return new_model
end

# Finally, we define a function to apply the model to data.  This is a bit more complicated, as we need to do some data manipulation to get the data into the right shape.
# Basically, we merge teh market data with the intercecpt data (so that their time indices are aligned to the input), and then subtract the intercept (``\alpha``), 
# and the slope (``\beta``) times the market data from the data.
function StatsBase.predict(model::MarketModel, data::TSFrame)
    ret = deepcopy(data)
    market_data = TSFrame(TSFrames.DataFrames.leftjoin(data.coredata, model.market_returns.coredata; on = :Index))
    for col in names(data)
        ret.coredata[!, col] = data.coredata[!, col] .- model.coefs[1] .- model.coefs[2] .* market_data.coredata[!, first(names(model.market_returns))]
    end
    return ret
end


# Below is some code to make use of this market model:
# ```julia
# model = MarketModel(nifty_returns)
# GLM.StatsBase.fit!(model, data)
# ret = apply(model, TSFrame(data.coredata[5000:end, :]))

# f, a, p = lines(Dates.value.(index(data)[5000:end] .- Date(2015, 1, 1)), (TSFrame(data.coredata[5000:end, [:var"RELIANCE.NS"]]) |> EventStudies.remap_cumsum).var"RELIANCE.NS"; label = "RELIANCE.NS")
# dmret = TSFrame(dropmissing(ret.coredata))
# p2 = lines!(a, Dates.value.(index(dmret) .- Date(2015, 1, 1)), (dmret |> EventStudies.remap_cumsum).var"RELIANCE.NS"; label = "Reliance after market model")
# nmnr = TSFrame(dropmissing(nifty_returns.coredata))
# p2 = lines!(a, Dates.value.(index(nmnr) .- Date(2015, 1, 1)), (nmnr |> EventStudies.remap_cumsum).var"NIFTY"; label = "NIFTY index")
# Makie.current_figure()
# xlims!(a, 0, nothing)
# f
# axislegend(a, position = :rb)
# a.title = "Market model on NIFTY index"
# f
# ```
