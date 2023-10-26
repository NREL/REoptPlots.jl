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
function plot_electric_dispatch(d::Dict; title="Electric Systems Dispatch", save_html=false, display_stats=false, year=2017)
    
    traces = GenericTrace[]
    layout = Layout(
        hovermode="closest",
        hoverlabel_align="left",
        plot_bgcolor="white",
        paper_bgcolor="white",
        font_size=18,
        xaxis=attr(showline=true, ticks="outside", showgrid=false,linewidth=1.5, zeroline=false),
        yaxis=attr(showline=true, ticks="outside", showgrid=true,linewidth=1.5, zeroline=false, color="black"),
        title = title,
        xaxis_title = "",
        yaxis_title = "Power (kW)",
        xaxis_rangeslider_visible=true,
        legend=attr(x=1.17, y=0.5, font=attr(size=14,color="black")))
    
    tech_names  = ["ElectricUtility", "PV", "ElectricStorage", "Generator", "Wind", "CHP", "GHP"]
    eload = d["ElectricLoad"]["load_series_kw"]
    keys = ["storage_to_load_series_kw", "electric_to_load_series_kw", "electric_to_grid_series_kw", "electric_to_storage_series_kw", "electric_curtailed_series_kw"]

    # Colors for dispatch plot
    colors = Dict()
    colors["ElectricUtility"] = Dict(
        "electric_to_load_series_kw" => "#434746",
        "electric_to_storage_series_kw" => "#5C6B64"
    )
    colors["PV"] = Dict(
        "electric_to_load_series_kw" => "#FA8F3D",
        "electric_to_grid_series_kw" => "#FA6C52",
        "electric_to_storage_series_kw" => "#F95994",
        "electric_curtailed_series_kw" => "#FAB952"
    )
    colors["ElectricStorage"] = Dict(
        "storage_to_load_series_kw" => "#003A00",
    )
    colors["Generator"] = Dict(
        "electric_to_load_series_kw" => "rebeccapurple",
        "electric_to_grid_series_kw" => "thistle1",
        "electric_to_storage_series_kw" => "mediumorchid3"
    )
    colors["Wind"] = Dict(
        "electric_to_load_series_kw" => "lightskyblue1",
        "electric_to_grid_series_kw" => "lightblue1",
        "electric_to_storage_series_kw" => "deepskyblue3",
        "electric_curtailed_series_kw" => "cadetblue1"
    )
    colors["CHP"] = Dict(
        "electric_to_grid_series_kw" => "lightgoldenrod1",
        "electric_to_storage_series_kw" => "orange",
        "electric_to_load_series_kw" => "darkorange2"

    )
    # TODO: add GHP to colors 

    # Define the start and end time for the date and time array
    start_time = DateTime(year, 1, 1, 0, 0, 0)
    end_time = DateTime(year+1, 1, 1, 0, 0, 0)

    # Create the date and time array with the specified time interval
    dr = start_time:check_time_interval(eload):end_time
    dr_v = collect(dr) 
    pop!(dr_v) # pop removes last ts

    if display_stats
        ###Plot Stats
        df_stat = rec_flatten_dict(d)
        load  = get(df_stat,"ElectricLoad.load_series_kw","-")
        avg_val = round(mean(load))
        max_val = round(maximum(load))
        min_val = round(minimum(load))

        x_stat = [first(dr_v),dr_v[end-100]]
        y_stat1 = [min_val,min_val]
        y_stat2 = [max_val,max_val]
        y_stat3 = [avg_val,avg_val]
        
        push!(traces, scatter(
        x = x_stat,
        y = y_stat1,
        showlegend = false,
        legendgroup="group2",
        line=attr(color="grey", width=0.5,
                                dash="dot"),
        mode="lines+text",
        name=String("Min = $(min_val) kW"),
        text=[String("Min = $(min_val) kW")],
        textposition="top right"
            )
        )

        push!(traces, scatter(
        x = x_stat,
        y = y_stat2,
        showlegend = false,
        legendgroup="group2",
        line=attr(color="grey", width=0.5,
                                dash="dot"),
        mode="lines+text",
        name=String("Max = $(max_val) kW"),
        text=[String("Max = $(max_val) kW")],
        textposition="top right"
            )
        )

        push!(traces, scatter(
        x = x_stat,
        y = y_stat3,
        showlegend = false,
        legendgroup="group2",
        line=attr(color="grey", width=0.5,
                                dash="dot"),
        mode="lines+text",
        name=String("Avg = $(avg_val) kW"),
        text=[String("Avg = $(avg_val) kW")],
        textposition="top right"
            )
        )
    end

    ### REopt Data Plotting Begins
    ### Total Electric Load Line Plot
    push!(traces, scatter(;
        name = "Total Electric Load",
        x = dr_v,
        y = d["ElectricLoad"]["load_series_kw"],
        mode = "lines",
        fill = "none",
        line=attr(width=1, color="black")
    ))

    ### Grid to Load Plot
    push!(traces, scatter(;
        name = "Grid to Load",
        x = dr_v,
        y = d["ElectricUtility"]["electric_to_load_series_kw"],
        mode = "lines",
        fill = "tozeroy",
        line = attr(width=0, color=colors["ElectricUtility"]["electric_to_load_series_kw"])
    ))

    if haskey(d, "ElectricStorage")
        ### Battery SOC line plot
        push!(traces, scatter(
            name = "Battery State of Charge",
            x = dr_v,
            y = d["ElectricStorage"]["soc_series_fraction"]*100,
            yaxis="y2",
            line = attr(
            dash= "dashdot",
            width = 1
            ),
            marker = attr(
                color="rgb(100,100,100)"
            ),
        ))

        layout = Layout(
            hovermode="closest",
            hoverlabel_align="left",
            plot_bgcolor="white",
            paper_bgcolor="white",
            font_size=18,
            xaxis=attr(showline=true, ticks="outside", showgrid=false,
                linewidth=1.5, zeroline=false),
            yaxis=attr(showline=true, ticks="outside", showgrid=false,
                linewidth=1.5, zeroline=false),
            xaxis_title = "",
            yaxis_title = "Power (kW)",
            xaxis_rangeslider_visible=true,
            legend=attr(x=1.17, y=0.5, 
                        font=attr(
                        size=14,
                        color="black")
                        ),
            yaxis2 = attr(
                title = "State of Charge (Percent)",
                overlaying = "y",
                side = "right"
            ))

    end

    # Plot every existing technology
    cumulative_data = zeros(length(dr_v))
    cumulative_data = cumulative_data .+ d["ElectricUtility"]["electric_to_load_series_kw"]
    for key in keys
        for tech in tech_names
            if haskey(d,tech)
                if tech == "ElectricUtility" && key == "electric_to_load_series_kw"
                    continue
                else
                    sub_dict = d[tech]
                    if haskey(sub_dict, key) && sum(sub_dict[key]) != 0.0
                                
                        #invisble line for plotting
                        push!(traces, scatter(
                            name = "invisible",			
                            x = dr_v,
                            y = cumulative_data,
                            mode = "lines",
                            fill = Nothing,
                            line = attr(width = 0),
                            showlegend = false,
                            hoverinfo = "skip",
                        )) 

                        new_data = sub_dict[key] 
                        cumulative_data = cumulative_data .+ new_data

                        if contains(key, "to_load")
                            txt = "Serving Load"
                        elseif contains(key, "to_grid")
                            txt = "Export to Grid"
                        elseif contains(key, "to_storage")
                            txt = "Charging Storage"
                        elseif contains(key, "curtailed")
                            txt = "Curtailed"
                        end

                        tech_name = tech
                        if tech == "ElectricUtility"
                            tech_name = "Grid"
                        end
                        
                        push!(traces, scatter(;
                            name = tech* " "*txt,
                            x = dr_v,
                            y = cumulative_data,
                            mode = "lines",
                            fill = "tonexty",
                            line = attr(width=0, color = colors[tech][key])
                        ))   
                    end
                end
            end
        end
    end

    p = plot(traces, layout)

    if save_html
        savefig(p, replace(title, " " => "_") * ".html")
    end

    plot(traces, layout)  # will not produce plot in a loop
end

function rec_flatten_dict(d, prefix_delim = ".")
    new_d = empty(d)
    for (key, value) in pairs(d)
        if isa(value, Dict)
             flattened_value = rec_flatten_dict(value, prefix_delim)
             for (ikey, ivalue) in pairs(flattened_value)
                 new_d["$key.$ikey"] = ivalue
             end
        else
            new_d[key] = value
        end
    end
    return new_d
end

function check_time_interval(arr::Array)
    if length(arr) == 8760
        interval = Dates.Hour(1)
    elseif length(arr) == 17520
        interval = Dates.Minute(30)
    elseif length(arr) == 35040
        interval = Dates.Minute(15)
    else
        error("Time interval length must be either 8760, 17520, or 35040")
    end
    return interval
end