module EventStudies

# Write your package code here.
using HypothesisTests, Bootstrap # for inference

include("inference.jl")
export inference, ClassicInference, BootstrapInference, WilcoxonInference
end
