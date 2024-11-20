# see documentation at https://juliadocs.github.io/Documenter.jl/stable/

using Documenter, OptimizationCallbacks

makedocs(
    modules = [OptimizationCallbacks],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Johanni Brea",
    sitename = "OptimizationCallbacks.jl",
    pages = Any["index.md"],
    remotes = nothing
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

# Some setup is needed for documentation deployment, see “Hosting Documentation” and
# deploydocs() in the Documenter manual for more information.
deploydocs(
    repo = "github.com/jbrea/OptimizationCallbacks.jl.git",
    push_preview = true
)
