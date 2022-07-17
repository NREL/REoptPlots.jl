module REoptPlots

using PlotlyJS
using Dates

export
    plot_violin_compare_soc_efc,
    plot_electric_dispatch,
    plot_thermal_dispatch

include("dispatch.jl")
include("battery_degradation.jl")

end # module
