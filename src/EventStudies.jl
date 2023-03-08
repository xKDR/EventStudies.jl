module EventStudies

using TSFrames, DataFrames

using HypothesisTests, Bootstrap # for inference

using GLM # for models

include("models.jl")
export NoModel, MarketModel, AugmentedMarketModel, ExcessReturn, ConstantMeanReturn
include("inference.jl")
export inference, ClassicInference, BootstrapInference, WilcoxonInference
include("eventstudy.jl")
export to_eventtime_windowed, levels_to_returns

end
