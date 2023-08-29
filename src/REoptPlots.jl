module REoptPlots

using PlotlyJS
using DataFrames
using Statistics
using Dates
using CSV
using JSON3

export
    plot_violin_compare_soc_efc,
    plot_electric_dispatch

include("dispatch.jl")
include("battery_degradation.jl")

end # module
