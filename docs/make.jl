using EventStudies
using Documenter
using Literate

DocMeta.setdocmeta!(EventStudies, :DocTestSetup, :(using EventStudies); recursive=true)

# First, generate markdown files from the examples!

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
        "Minimal example" => "mwe.md"
    ],
)

deploydocs(;
    repo="github.com/xKDR/EventStudies.jl",
    target = "build",
    devbranch="main",
    push_preview = true,
)
