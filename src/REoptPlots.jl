module REoptPlots

using PlotlyJS

export
    plot_violin_compare_soc_efc,
    plot_electric_dispatch

include("dispatch.jl")
include("battery_degradation.jl")

end # module
