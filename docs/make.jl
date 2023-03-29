# Set some environment variables for display
ENV["DATAFRAMES_ROWS"] = 5

using Documenter
using Literate

using EventStudies
using CairoMakie
CairoMakie.activate!(pt_per_unit = 0.75, type = :svg)
Makie.inline!(true)


DocMeta.setdocmeta!(
    EventStudies, 
    :DocTestSetup, 
    quote 
        using EventStudies, Makie
        Makie.inline!(true)
    end;
    recursive=true
)

# Copy the README over as index.md
cp(joinpath(dirname(@__DIR__), "README.md"), joinpath(@__DIR__, "src", "index.md"))

# Generate markdown files from the examples!
example_path = joinpath(dirname(@__DIR__), "examples")
literate_files = joinpath.(
    example_path,
    [
        "mwe.jl",
        "nifty.jl",
        "sex_ratio_at_birth.jl",
        "replications.jl",
    ]
)

for file in literate_files
    Literate.markdown(file, joinpath(@__DIR__, "src", "examples"); documenter = true)
end

# also make the definition of `MarketModel` a Literate file (but do not execute)
Literate.markdown(joinpath(@__DIR__, "..", "src", "Models", "marketmodel.jl"), joinpath(@__DIR__, "src"); documenter = false)

makedocs(;
    modules=[EventStudies],
    authors="xKDR Forum",
    repo="https://github.com/xKDR/EventStudies.jl/blob/{commit}{path}#{line}",
    sitename="$EventStudies.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://xKDR.github.io/EventStudies.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Event time" => "event_time.md",
        "Models" => "models.md",
        "Examples" => [
            "Minimal example" => "examples/mwe.md",
            "Rate hikes and market indicators" => "examples/nifty.md",
            "Sex ratio at birth" => "examples/sex_ratio_at_birth.md",
            "Replicating eventstudies.R" => "examples/replications.md",
        ],
        "Developer docs" => [
            "Artifacts and data" => "artifacts.md",
            "Market model implementation" => "marketmodel.md",
        ]
    ],
)

deploydocs(;
    repo="github.com/xKDR/EventStudies.jl",
    target = "build",
    devbranch="main",
    push_preview = true,
)
