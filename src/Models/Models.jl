module Models

using TSFrames
using TSFrames.DataFrames
using GLM
using GLM.StatsBase
import StatsBase: fit, fit!
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

function apply(model::AbstractModel, data::TSFrame)
    error("Not implemented yet for model type $(typeof(model))")
end

export fit, fit!, apply

include("marketmodel.jl")
export MarketModel, MarketModelResult


end