abstract type InferenceMethod end

"""
    ClassicInference()

Creates an instance of `ClassicInference` for use in [`inference`](@ref). 
This forwards to the T-test from [HypothesisTests.jl](https://github.com/JuliaStats/HypothesisTests.jl).
"""
struct ClassicInference <: InferenceMethod
end

"""
    BootstrapInference(sampling_method::Bootstrap.BootstrapSampling)
    BootstrapInference(; replicates = 1000)

Creates an instance of `BootstrapSampling` for use in [`inference`](@ref).  
This can be constructed using a `Bootstrap.BootstrapSampling` subtype directly,
or by the convenience keyword constructor which creates a BootstrapInference backed
by `BasicSampling`.

## Available sampling methods

- Random resampling with replacement ([`BasicSampling`](@ref))
- Antithetic resampling, introducing negative correlation between samples ([`AntitheticSampling`](@ref))
- Balanced random resampling, reducing bias ([`BalancedSampling`](@ref))
- Exact resampling, iterating through all unique resamples ([]`ExactSampling`](@ref)): deterministic bootstrap, suited for small samples sizes
- Resampling of residuals in generalized linear models ([`ResidualSampling`](@ref), [`WildSampling`](@ref))
- Maximum Entropy bootstrapping for dependent and non-stationary datasets ([`MaximumEntropySampling`](@ref))
"""
struct BootstrapInference <: InferenceMethod
    sampling_method::Bootstrap.BootstrapSampling
end

BootstrapInference(; replicates = 1000) = BootstrapInference(BasicSampling(replicates))

"""
    WilcoxonInference(; exact = nothing)

Creates an instance of `WilcoxonInference` for use in [`inference`](@ref). 
This forwards to the Wilcoxon inference test from [HypothesisTests.jl](https://github.com/JuliaStats/HypothesisTests.jl).

If `exact = nothing`, then a heuristic determines whether to use the exact or 
approximate Wilcoxon signed-rank test.  If `exact = true`, then the exact test
is used; if `exact = false`, then the approximate test is used.
"""
struct WilcoxonInference{Exact} <: InferenceMethod
end

function WilcoxonInference(; exact = nothing)
    @assert exact === nothing || exact isa Bool
    return WilcoxonInference{exact}()
end

# now, define the inference methods on TSFrames

"""
    inference(::ClassicInference, ts::TSFrame, conf = 0.975)

Performs classic T-test inference and returns a tuple of vectors `(t₀, lower, upper)`.
"""
function inference(::ClassicInference, ts::TSFrame, conf = 0.975)
    # First, we conduct a hypothesis test on each row of the TSFrame,
    # assuming the mean is zero.
    hypothesis_tests = map(eachrow(ts.coredata[!, Not(:Index)])) do row
        HypothesisTests.OneSampleTTest(collect(row), 0)
    end

    # Then, we collect the confidence intervals.
    conf_ints = HypothesisTests.confint.(hypothesis_tests; level = 0.975, tail = :both)

    return (
        map(mean, collect.(eachrow(ts.coredata[!, Not(:Index)]))), # t0
        getindex.(conf_ints, 1), # lower
        getindex.(conf_ints, 2)  # upper
    )
end

"""
    inference(inf::BootstrapInference, ts::TSFrame, conf = 0.975)

Performs bootstrap inference and returns a tuple of vectors `(t₀, lower, upper)`.
"""
function inference(bparams::BootstrapInference, ts::TSFrame, conf = 0.975)
    # collect the TSFrame into a matrix, so we can get observations
    observation_matrix = permutedims(Matrix(ts))
    # run bootstrap tests at each time point
    bootstrap_tests = bootstrap.(mean, eachcol(observation_matrix), (bparams.sampling_method,))
    # collect the confidence intervals
    confints = confint.(bootstrap_tests, (PercentileConfInt(0.975),)) .|> first
    # The `confint` function returns a `Tuple{Tuple{...}}` for some reason,
    # so we need to dereference that first tuple to get `(t0, lower, upper)`.
    # That's why we broadcast-pipe to `first` above.

    # This returns a tuple of vectors (t0, lower, upper).
    return getindex.(confints, 1), getindex.(confints, 2), getindex.(confints, 3)
end

"""
    inference(::WilcoxonInference{ExactType}, ts::TSFrame, conf = 0.975) where ExactType

Performs Wilcoxon signed-rank inference and returns a tuple of vectors `(t₀, lower, upper)`.
"""
function inference(::WilcoxonInference{ExactType}, ts::TSFrame, conf = 0.975) where ExactType
    TestType = if ExactType === nothing
        SignedRankTest
    elseif ExactType
        ExactSignedRankTest
    elseif !ExactType
        ApproximateSignedRankTest
    else
        error("WilcoxonInference can only have nothing, true or false as a type parameter; got WilcoxonInference{$ExactType}.")
    end

    hypothesis_tests = map(eachrow(ts.coredata[!, Not(:Index)])) do row
        TestType(collect(row))
    end

    # Then, we collect the confidence intervals.
    conf_ints = HypothesisTests.confint.(hypothesis_tests; level = 0.975, tail = :both)

    return (
        map(mean, collect.(eachrow(ts.coredata[!, Not(:Index)]))), # t0
        getindex.(conf_ints, 1), # lower
        getindex.(conf_ints, 2)  # upper
    )
end