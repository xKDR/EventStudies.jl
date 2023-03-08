module EventStudies

# Write your package code here.
using HypothesisTests, Bootstrap # for inference

using GLM # for models

include("models.jl")
export NoModel, MarketModel, AugmentedMarketModel, ExcessReturn, ConstantMeanReturn
include("inference.jl")
export inference, ClassicInference, BootstrapInference, WilcoxonInference
end
