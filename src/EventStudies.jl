module EventStudies

using Pkg, Dates, Statistics
using Pkg.Artifacts

using TSFrames, DataFrames
using RData, CodecXz, CSV # used only to load example data!

using ThreadPools # efficient multithreading

using HypothesisTests, Bootstrap # for inference

using GLM # for models

assetpath(args...) = joinpath(dirname(@__DIR__), "assets", args...)

include("data.jl")
export load_data

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

artifact"eventstudies_r_data" |> readdir

end
