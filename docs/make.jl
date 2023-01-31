using Pkg
pkg"activate .."

using Documenter, LARSplitting2D, DocumenterMarkdown
using DocumenterTools: Themes

makedocs(
    format = Documenter.HTML(
		prettyurls = get(ENV, "CI", nothing) == "true"
	), 
    sitename="LARSplitting2D.jl",
    pages=[
        "Home" => "index.md",
        "Documentazione" => [
            "Studio Preliminare" => "studioPreliminare.md",
            "Studio Esecutivo" => "studioEsecutivo.md",
            "Studio Definitivo" => "studioDefinitivo.md",
        ],
    ],
    modules=[LARSplitting2D]
)

deploydocs(
    repo="github.com/GiuliaCastagnacci/LARSplitting2D.git" 
)
