# Artifacts for example data

We use [`Artifacts`](https://pkgdocs.julialang.org/v1/artifacts/) to ship example data around, so it doesn't crowd the repository and cause download times to increase significantly.

In order to update the artifacts, you can upload tarballs of files to a release, then use the excellent `ArtifactUtils.jl` package and its `ArtifactUtils.add_artifact!` function to bind new artifacts to the names `eventstudies_r_data` and `eventstudies_csv_data` when in the `EventStudies.jl` environment.

Then, it's as simple as pushing the new changes to Github!

!!! danger
    It is very important that you do not overwrite any artifact; instead, always make one with a new name or in a new release.

These Artifacts are downloaded on release, and `load_data` accesses files within them.
