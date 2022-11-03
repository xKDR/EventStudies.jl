using EventStudies
using Documenter

DocMeta.setdocmeta!(EventStudies, :DocTestSetup, :(using EventStudies); recursive=true)

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
    ],
)

deploydocs(;
    repo="github.com/xKDR/EventStudies.jl",
    target = "build",
    devbranch="main"
)
