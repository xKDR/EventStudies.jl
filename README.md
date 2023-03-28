# EventStudies

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://xKDR.github.io/EventStudies.jl/dev)
![Build Status](https://github.com/xKDR/EventStudies.jl/actions/workflows/ci.yml/badge.svg)
![Build Status](https://github.com/xKDR/EventStudies.jl/actions/workflows/documentation.yml/badge.svg)
[![codecov](https://codecov.io/gh/xKDR/EventStudies.jl/branch/main/graph/badge.svg?token=RE0DGBXNQM)](https://codecov.io/gh/xKDR/EventStudies.jl)

This package is made to conduct event studies in Julia.

# Installation

The package is currently unregistered, so you can install directly by URL.  This will change in the future!

```julia
using Pkg
Pkg.add(url = "https://github.com/xKDR/EventStudies.jl")
```

# Usage

The main entry point is the [`eventstudy`](@ref) function, which takes in a `TSFrame` (from [TSFrames.jl](https://github.com/xKDR/TSFrames.jl)) and a vector of event times, and returns a `TSFrame` of the timeseries in "event time".

Here's a quick example of running 

```julia
EventStudies.assetpath(...)
spr = zoo_to_tsframe(EventStudies.asset("StockPriceReturns"))
eventtime_returns_tsframe, event_success_codes = eventstudy(levels_to_returns(market_data), colnames .=> event_times, #= window width =# 4)
```

# Models

You can provide a model in the last parameter of `eventstudy`, which is automatically parallelized based on how many threads you started Julia with.
