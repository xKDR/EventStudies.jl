module EventStudies

using Dates, Statistics

using TSFrames, DataFrames
using RData # RData is used only for examples!

using ThreadPools # efficient multithreading

using HypothesisTests, Bootstrap # for inference

using GLM # for models

assetpath(args...) = joinpath(dirname(@__DIR__), "assets", args...)

include("utils.jl")
export remap_cumsum, levels_to_returns # remove before release
# include("models.jl")
# export NoModel, MarketModel, AugmentedMarketModel, ExcessReturn, ConstantMeanReturn
include("Models/Models.jl")
using .Models
export fit, fit!, apply
export MarketModel, MarketModelResult

include("inference.jl")
export inference, ClassicInference, BootstrapInference, WilcoxonInference
include("eventstudy.jl")
export eventstudy

end
