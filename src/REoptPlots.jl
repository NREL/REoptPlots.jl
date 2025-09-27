module REoptPlots

using PlotlyJS
using Plots
using JuMP
using DataFrames
using Statistics
using Dates
using CSV
using JSON3
using REopt

export
    plot_violin_compare_soc_efc,
    plot_electric_dispatch

include("dispatch.jl")
include("battery_degradation.jl")
include("multinode_plots.jl")

end # module
