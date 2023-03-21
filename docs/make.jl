using EventStudies
using Documenter
using Literate

DocMeta.setdocmeta!(EventStudies, :DocTestSetup, :(using EventStudies); recursive=true)

# First, generate markdown files from the examples!
example_path = joinpath(@__DIR__, "..", "examples")
literate_files = joinpath.(
    example_path,
    [
        "mwe.jl",
        "stock_splits.jl",
        "nifty.jl",
        "sex_ratio_at_birth.jl"
    ]
)

for file in literate_files
    Literate.markdown(file, joinpath(@__DIR__, "src", "examples"); documenter = true)
end
Literate.markdown(joinpath(@__DIR__, "..", "examples", "mwe.jl"), joinpath(@__DIR__, "src"); documenter = true)

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
        "Models" => "models.md",
        "Examples" => [
            "Minimal example" => "mwe.md",
            "Stock splits" => "stock_splits.md",
            "Rate hikes and market indicators" => "nifty.md",
            "Sex ratio at birth" => "sex_ratio_at_birth.md"
        ]
    ],
)

deploydocs(;
    repo="github.com/xKDR/EventStudies.jl",
    target = "build",
    devbranch="main",
    push_preview = true,
)
