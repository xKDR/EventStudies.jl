"""
    Models

This module implements several decorrelating models for event studies.

## API

The basic API which any `struct MyModel <: Models.AbstractModel` needs to implement is:
- `StatsBase.fit!(model::MyModel, data::TSFrame)`
- `StatsBase.predict(model::MyModel, data::TSFrame)`

There is a convenience which allows any model to be fit using `StatsBase.fit(model, data)`.
In general, the model can be constructed ahead of time by providing the index or market data 
which it needs to predict.  Then, the model can be fit to the data using `StatsBase.fit!(model, data)`.
Finally, the model can be applied to the data using `StatsBase.predict(model, data)`.

## Models
- [`MarketModel`](@ref): A basic market model which calculates ``r_{ind} = r_{firm} - \\alpha - \\beta * r_{market}```
- [`AugmentedMarketModel`](@ref)
"""
module Models

using TSFrames
using TSFrames.DataFrames
using GLM
using GLM.StatsBase
import StatsBase: fit, fit!, predict
using DocStringExtensions

"""
    abstract type Models.AbstractModel

Abstract type for models used in EventStudies.jl.
Any model should implement the `StatsBase.fit!(model, data::TSFrame)`
and `Models.apply(model, data::TSFrame)`.
"""
abstract type AbstractModel end


function StatsBase.fit(::Type{<: AbstractModel}, params, data::TSFrame; kwargs...)
    return StatsBase.fit!(AbstractModel(params...; kwargs...), data)
end

function StatsBase.fit(model::AbstractModel, data::TSFrame)
    return StatsBase.fit!(deepcopy(model), data)
end

function StatsBase.fit!(model::AbstractModel, data::TSFrame)
    error("Not implemented yet for model type $(typeof(model)).")
end

function StatsBase.predict(model::AbstractModel, data::TSFrame)
    error("Not implemented yet for model type $(typeof(model))")
end

function check_window(model, window)
    true
end

export fit, fit!, predict, check_window

include("simplemodels.jl")
export ConstantMeanReturn, ExcessReturn

include("marketmodel.jl")
export MarketModel

include("augmentedmarketmodel.jl")
export AugmentedMarketModel

end