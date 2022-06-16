# *********************************************************************************
# REopt, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************

function plot_electric_dispatch(d::Dict; title="Electric Systems Dispatch", save_html=false)

    traces = PlotlyJS.GenericTrace[]

    layout = PlotlyJS.Layout(
        title_text = title,
        xaxis_title_text = "time step",
        yaxis_title_text = "kW"
    )
    
    eload = d["ElectricLoad"]["load_series_kw"]
    T = length(eload)

    push!(traces, PlotlyJS.scatter(
        name = "total load",
        x = 1:T,
        y = d["ElectricLoad"]["load_series_kw"],
        fill = "none",
        line = PlotlyJS.attr(
            width = 3
        ),
    ))

    push!(traces, PlotlyJS.scatter(
        name = "grid supply",
        x = 1:T,
        y = d["ElectricUtility"]["year_one_to_load_series_kw"],
        fill = "tozeroy",
        marker = PlotlyJS.attr(
            color="rgb(12,12,12)",
        ),
        line = PlotlyJS.attr(
            width = 0
        ),
    ))
    # invisible line for stacking
    push!(traces, PlotlyJS.scatter(
        name = "invisible",
        x = 1:T,
        y = d["ElectricUtility"]["year_one_to_load_series_kw"],
        fill = Nothing,
        line = PlotlyJS.attr(
            width = 0
        ),
        showlegend = false,
        hoverinfo = "skip",
    ))

    pv_to_load = zeros(T)
    if "PV" in keys(d)  # TODO multiple PVs
        pv_to_load = d["PV"]["year_one_to_load_series_kw"]
        push!(traces, PlotlyJS.scatter(
            name = "PV+grid supply",
            x = 1:T,
            y = pv_to_load .+ d["ElectricUtility"]["year_one_to_load_series_kw"],
            fill = "tonexty",
            marker = PlotlyJS.attr(
                color="rgb(255, 127, 14)",
            ),
            line = PlotlyJS.attr(
                width = 0
            ),
        ))
    end

    layout = PlotlyJS.Layout()

    if "ElectricStorage" in keys(d)
        # invisible line for stacking
        push!(traces, PlotlyJS.scatter(
            name = "invisible",
            x = 1:T,
            y = d["ElectricUtility"]["year_one_to_load_series_kw"] .+ pv_to_load,
            fill = Nothing,
            line = PlotlyJS.attr(
                width = 0
            ),
            showlegend = false,
            hoverinfo = "skip",
        ))
        push!(traces, PlotlyJS.scatter(
            name = "battery+PV+grid supply",
            x = 1:T,
            y = d["ElectricUtility"]["year_one_to_load_series_kw"] .+ pv_to_load .+ d["ElectricStorage"]["year_one_to_load_series_kw"],
            fill = "tonexty",
            marker = PlotlyJS.attr(
                color="rgb(44, 160, 44)",
            ),
            line = PlotlyJS.attr(
                width = 0
            ),
        ))
        push!(traces, PlotlyJS.scatter(
            name = "ElectricStorage SOC",
            x = 1:T,
            y = d["ElectricStorage"]["year_one_soc_series_pct"],
            yaxis="y2",
            marker = PlotlyJS.attr(
                color="rgb(100,100,100)",
            ),
        ))

        layout = PlotlyJS.Layout(
            title_text = title,
            xaxis_title_text = "time step",
            yaxis_title_text = "kW",
            yaxis2 = PlotlyJS.attr(
                title = "SOC",
                overlaying = "y",
                side = "right"
            )
        )
    end
    p = PlotlyJS.plot(traces, layout)

    if save_html
        PlotlyJS.savefig(p, replace(title, " " => "_") * ".html")
    end

    PlotlyJS.plot(traces, layout)  # will not produce plot in a loop

end

function plot_thermal_dispatch(d::Dict; title="Thermal Systems Dispatch", save_html=false)

    traces = PlotlyJS.GenericTrace[]

    layout = PlotlyJS.Layout(
        title_text = "",
        xaxis_title_text = "time step",
        yaxis_title_text = "kW",
        yaxis2 = (
            title = "temp [C]",
            overlaying = "y",
            side = "right"
        )
    )

    if "ExistingChiller" in keys(d)
        T = length(d["ExistingChiller"]["year_one_electric_consumption_series"])
    else
        T = 8760
    end
    
    # x axis resolution is determined by length of T.
    x_axis = DateTime(2021):Dates.Minute(Int(60*(8760/T))):DateTime(2021,12,31,23,45)

    node_temps_bau = zeros(T)
    node_temps = zeros(T)

    if "FlexibleHVAC" in keys(d)
        node_temps_bau = reduce(hcat,d["FlexibleHVAC"]["temperatures_degC_node_by_time_bau"])'[:,3]
        push!(traces, PlotlyJS.scatter(
            name = "BAU node temps",
            x = x_axis,
            y = node_temps_bau,
            line = PlotlyJS.attr(
                width = 1
            ),
            yaxis = "y2",
        ))

        node_temps = reduce(hcat,d["FlexibleHVAC"]["temperatures_degC_node_by_time"])'[:,3]
        push!(traces, PlotlyJS.scatter(
            name = "Node temps",
            x = x_axis,
            y = node_temps,
            line = PlotlyJS.attr(
                width = 1
            ),
            yaxis = "y2",
        ))
    end;

    if "ExistingChiller" in keys(d)
        elec_chiller_to_load = d["ExistingChiller"]["year_one_electric_consumption_series"]
        push!(traces, PlotlyJS.scatter(
            name = "Elec. chiller kWh series",
            x = x_axis,
            y = elec_chiller_to_load,
            line = PlotlyJS.attr(
                width = 1
            ),
        ))
    end;

    p = PlotlyJS.plot(traces, layout)

    if save_html
        PlotlyJS.savefig(p, replace(title, " " => "_") * ".html")
    end

    return PlotlyJS.plot(traces, layout)
end;