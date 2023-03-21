module Models

using ..TSFrames
using TSFrames.DataFrames
using ..GLM
using GLM.StatsBase

"""
"""
abstract type AbstractModel end

"""
"""
abstract type AbstractModelResult end

function GLM.StatsBase.fit(model::AbstractModel, data::TSFrame)
    error("Not implemented yet for model type $(typeof(model)).")
end

function apply(result::AbstractModelResult, data::TSFrame)
    error("Not implemented yet for model type $(typeof(model))")
end

export GLM.StatsBase.fit, apply

include("marketmodel.jl")
export MarketModel, MarketModelResult


end