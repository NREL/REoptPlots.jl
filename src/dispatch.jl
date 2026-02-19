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
function plot_electric_dispatch(d::Dict; title="Electric Systems Dispatch", save_html=false, display_stats=false, show_soc=false, year=2017, 
    other_timeseries::Array{<:Real,1} = Real[], other_timeseries_name::String = "", other_timeseries_units::String = "")
    
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
    
    tech_names  = ["ElectricUtility", "PV", "ElectricStorage", "Generator", "Wind", "CHP", "SteamTurbine"]
    eload = d["ElectricLoad"]["load_series_kw"]
    keys = ["storage_to_load_series_kw", "storage_to_grid_series_kw", "electric_to_load_series_kw", "electric_to_grid_series_kw", "electric_to_storage_series_kw", "electric_curtailed_series_kw"]

    # Colors for dispatch plot
    colors = Dict()
    colors["ElectricUtility"] = Dict(
        "electric_to_load_series_kw" => "#434746",
        "electric_to_storage_series_kw" => "#5C6BB3"
    )
    colors["PV"] = Dict(
        "electric_to_load_series_kw" => "RGBA(255, 89, 0, 1.0)", # Dark orange
        "electric_to_grid_series_kw" => "RGBA(255, 108, 82, 1.0)",
        "electric_to_storage_series_kw" => "RGBA(212, 23, 155, 1.0)",
        "electric_curtailed_series_kw" => "RGBA(255, 210, 82, 1.0)"
    )
    colors["ElectricStorage"] = Dict(
        "storage_to_load_series_kw" => "#003A00",
        "storage_to_grid_series_kw" => "#81A41C"
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
        "electric_to_grid_series_kw" => "RGBA(57, 254, 255, 1.0)",
        "electric_to_storage_series_kw" => "orange",
        "electric_to_load_series_kw" => "darkorange2"

    )
    colors["SteamTurbine"] = Dict(
        "electric_to_load_series_kw" => "lightsteelblue",
        "electric_to_grid_series_kw" => "steelblue",
        "electric_to_storage_series_kw" => "lightslategray"
    )

    # Define the start and end time for the date and time array
    start_time = DateTime(year, 1, 1, 0, 0, 0)
    end_time = DateTime(year+1, 1, 1, 0, 0, 0)

    # Create the date and time array with the specified time interval
    dr = start_time:check_time_interval(eload):end_time
    dr_v = collect(dr) 
    pop!(dr_v) # pop removes last ts

    if display_stats
        ###Plot Stats
        # TODO: Update this to use total load, rather than load_series_kw which is actually the BAU Load
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
    ### BAU Electric Load Line Plot
    # Dotted line for BAU electric load
    push!(traces, scatter(;
        name = "BAU Electric Load",
        x = dr_v,
        y = d["ElectricLoad"]["load_series_kw"],
        mode = "lines",
        fill = nothing,
        line=attr(width=1, color="black", dash="dot")
    ))
    # Sum all series that contain "electric_to_load_series_kw" or "storage_to_load_series_kw" to get total electric load line plot
    total_load = sum(
        get(d[tech], "electric_to_load_series_kw", zeros(length(dr_v))) +
        get(d[tech], "storage_to_load_series_kw", zeros(length(dr_v)))
        for tech in tech_names if haskey(d, tech) && 
            (haskey(d[tech], "electric_to_load_series_kw") || haskey(d[tech], "storage_to_load_series_kw")) && 
            (!isempty(get(d[tech], "electric_to_load_series_kw", [])) || !isempty(get(d[tech], "storage_to_load_series_kw", []))) && 
            (sum(get(d[tech], "electric_to_load_series_kw", [0.0])) != 0.0 || sum(get(d[tech], "storage_to_load_series_kw", [0.0])) != 0.0)
    )
    push!(traces, scatter(;
        name = "Total Electric Load",
        x = dr_v,
        y = total_load,
        mode = "lines",
        fill = nothing,
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

    if !show_soc && length(other_timeseries) > 0
        push!(traces, scatter(
                name = other_timeseries_name,
                x = dr_v,
                y = other_timeseries,
                yaxis="y2",
                line = attr(
                    dash= "dashdot",
                    width = 1
                ),
                marker = attr(
                    color="rgb(100,100,100)"
                ),
            )
        )
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
                title = other_timeseries_units,
                overlaying = "y",
                side = "right"
            ))
    end

    if haskey(d, "ElectricStorage") && d["ElectricStorage"]["size_kw"] > 0.0
        if show_soc
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
                    # check for multiple PVs
                    if tech == "PV" && !isa(d[tech], Dict)
                        for i in range(1,length(d[tech]))
                            sub_dict = d[tech][i]
                            if haskey(sub_dict, key) && sum(sub_dict[key]) != 0.0
                                    
                                #invisble line for plotting
                                push!(traces, scatter(
                                    name = "invisible",			
                                    x = dr_v,
                                    y = cumulative_data,
                                    mode = "lines",
                                    fill = nothing,
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
                                
                                c = colors[tech][key]
                                grad = parse(Float64,split(c,",")[4][2:4]) - 0.1 * (i-1)
                                colorpv = join(split(c,",")[1:3],",")*", $(grad))"

                                push!(traces, scatter(;
                                    name = tech* "$(i) "*txt,
                                    x = dr_v,
                                    y = cumulative_data,
                                    mode = "lines",
                                    fill = "tonexty",
                                    line = attr(width=0, color = colorpv) # parse(Float64,a[18:20]) - 0.2
                                ))   
                            end
                        end

                    else
                        sub_dict = d[tech]
                        if haskey(sub_dict, key) && !isempty(sub_dict[key]) && sum(sub_dict[key]) != 0.0
                                    
                            #invisble line for plotting
                            push!(traces, scatter(
                                name = "invisible",			
                                x = dr_v,
                                y = cumulative_data,
                                mode = "lines",
                                fill = nothing,
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
    end

    p = plot(traces, layout)

    if save_html
        savefig(p, replace(title, " " => "_") * ".html")
    end

    plot(traces, layout)  # will not produce plot in a loop
end


function plot_heating_thermal_dispatch(d::Dict; title="Thermal Systems Dispatch", save_html=false, year=2017, 
    other_timeseries::Array{<:Real,1} = Real[], other_timeseries_name::String = "", other_timeseries_units::String = "")

    bau_heating_load = d["HeatingLoad"]["total_heating_thermal_load_series_mmbtu_per_hour"]
    
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
        yaxis_title = "Heating Thermal Power (MMBtu/hr)",
        xaxis_rangeslider_visible=true,
        legend=attr(x=1.17, y=0.5, font=attr(size=14,color="black")))
    
    # Colors for dispatch plot
    colors = Dict()

    colors["CHP"] = Dict(
        "thermal_to_storage_series_mmbtu_per_hour"              => "RGBA(65, 105, 225, 1.0)",   # royalblue
        "thermal_curtailed_series_mmbtu_per_hour"               => "RGBA(90, 95, 94, 1.0)",     # dark gray
        "thermal_to_steamturbine_series_mmbtu_per_hour"         => "RGBA(255, 140, 0, 1.0)",    # darkorange
        "thermal_to_absorption_chiller_series_mmbtu_per_hour"   => "RGBA(148, 0, 211, 1.0)",    # darkviolet
        "thermal_to_dhw_load_series_mmbtu_per_hour"             => "RGBA(255, 215, 0, 1.0)",    # gold
        "thermal_to_space_heating_load_series_mmbtu_per_hour"   => "RGBA(60, 179, 113, 1.0)",   # mediumseagreen
        "thermal_to_process_heat_load_series_mmbtu_per_hour"    => "RGBA(220, 20, 60, 1.0)",    # crimson
    )
    colors["SteamTurbine"] = Dict(
        "thermal_to_storage_series_mmbtu_per_hour"                      => "RGBA(70, 130, 180, 1.0)",   # steelblue
        "thermal_to_high_temp_thermal_storage_series_mmbtu_per_hour"    => "RGBA(255, 69, 0, 1.0)",     # orangered (amber family)
        "thermal_to_absorption_chiller_series_mmbtu_per_hour"           => "RGBA(186, 85, 211, 1.0)",   # mediumorchid
        "thermal_to_dhw_load_series_mmbtu_per_hour"                     => "RGBA(255, 223, 70, 1.0)",   # bright gold
        "thermal_to_space_heating_load_series_mmbtu_per_hour"           => "RGBA(46, 139, 87, 1.0)",    # seagreen
        "thermal_to_process_heat_load_series_mmbtu_per_hour"            => "RGBA(255, 99, 71, 1.0)",    # tomato
    )
    colors["HotThermalStorage"] = Dict(
        "storage_to_steamturbine_series_mmbtu_per_hour"         => "RGBA(0, 128, 128, 1.0)",    # teal
        "storage_to_space_heating_load_series_mmbtu_per_hour"   => "RGBA(0, 139, 139, 1.0)",    # darkcyan
        "storage_to_dhw_load_series_mmbtu_per_hour"             => "RGBA(32, 178, 170, 1.0)",   # lightseagreen
        "storage_to_process_heat_load_series_mmbtu_per_hour"    => "RGBA(95, 158, 160, 1.0)",   # cadetblue
    )
    colors["HighTempThermalStorage"] = Dict(
        "storage_to_load_series_mmbtu_per_hour"             => "RGBA(0, 100, 0, 1.0)",      # darkgreen
        "storage_to_steamturbine_series_mmbtu_per_hour"     => "RGBA(72, 209, 204, 1.0)",   # mediumturquoise
    )
    colors["GHP"] = Dict(
        "thermal_to_space_heating_load_series_mmbtu_per_hour"   => "RGBA(102, 205, 170, 1.0)",  # mediumaquamarine
        "thermal_to_dhw_load_series_mmbtu_per_hour"             => "RGBA(255, 200, 50, 1.0)",   # warm gold
    )
    colors["ElectricHeater"] = Dict(
        "thermal_to_storage_series_mmbtu_per_hour"                      => "RGBA(135, 206, 250, 1.0)",  # lightskyblue
        "thermal_to_high_temp_thermal_storage_series_mmbtu_per_hour"    => "RGBA(255, 127, 80, 1.0)",   # coral (amber family)
        "thermal_to_steamturbine_series_mmbtu_per_hour"                 => "RGBA(255, 160, 80, 1.0)",   # light orange
        "thermal_to_absorption_chiller_series_mmbtu_per_hour"           => "RGBA(147, 112, 219, 1.0)",  # mediumpurple
        "thermal_to_dhw_load_series_mmbtu_per_hour"                     => "RGBA(240, 230, 140, 1.0)",  # khaki
        "thermal_to_space_heating_load_series_mmbtu_per_hour"           => "RGBA(144, 238, 144, 1.0)",  # lightgreen
        "thermal_to_process_heat_load_series_mmbtu_per_hour"            => "RGBA(250, 128, 114, 1.0)",  # salmon
    )
    colors["CST"] = Dict(
        "thermal_to_storage_series_mmbtu_per_hour"                      => "RGBA(100, 149, 237, 1.0)",  # cornflowerblue
        "thermal_to_high_temp_thermal_storage_series_mmbtu_per_hour"    => "RGBA(255, 83, 13, 1.0)",    # deep amber
        "thermal_to_steamturbine_series_mmbtu_per_hour"                 => "RGBA(255, 120, 0, 1.0)",    # vivid orange
        "thermal_curtailed_series_mmbtu_per_hour"                       => "RGBA(125, 132, 144, 1.0)",  # slate gray
        "thermal_to_absorption_chiller_series_mmbtu_per_hour"           => "RGBA(138, 43, 226, 1.0)",   # blueviolet
        "thermal_to_dhw_load_series_mmbtu_per_hour"                     => "RGBA(255, 210, 0, 1.0)",    # amber gold
        "thermal_to_space_heating_load_series_mmbtu_per_hour"           => "RGBA(34, 139, 34, 1.0)",    # forestgreen
        "thermal_to_process_heat_load_series_mmbtu_per_hour"            => "RGBA(205, 92, 92, 1.0)",    # indianred
    )
    colors["Boiler"] = Dict(
        "thermal_to_storage_series_mmbtu_per_hour"              => "RGBA(176, 196, 222, 1.0)",  # lightsteelblue
        "thermal_to_steamturbine_series_mmbtu_per_hour"         => "RGBA(205, 133, 63, 1.0)",   # peru (warm orange)
        "thermal_to_absorption_chiller_series_mmbtu_per_hour"   => "RGBA(153, 50, 204, 1.0)",   # darkorchid
        "thermal_to_dhw_load_series_mmbtu_per_hour"             => "RGBA(218, 165, 32, 1.0)",   # goldenrod
        "thermal_to_space_heating_load_series_mmbtu_per_hour"   => "RGBA(107, 142, 35, 1.0)",   # olivedrab
        "thermal_to_process_heat_load_series_mmbtu_per_hour"    => "RGBA(188, 143, 143, 1.0)",  # rosybrown
    )
    colors["ExistingBoiler"] = Dict(
        "thermal_to_storage_series_mmbtu_per_hour"              => "RGBA(119, 136, 153, 1.0)",  # lightslategray
        "thermal_to_steamturbine_series_mmbtu_per_hour"         => "RGBA(210, 105, 30, 1.0)",   # chocolate
        "thermal_to_absorption_chiller_series_mmbtu_per_hour"   => "RGBA(128, 0, 128, 1.0)",    # purple
        "thermal_to_dhw_load_series_mmbtu_per_hour"             => "RGBA(184, 134, 11, 1.0)",   # darkgoldenrod
        "thermal_to_space_heating_load_series_mmbtu_per_hour"   => "RGBA(85, 107, 47, 1.0)",    # darkolivegreen
        "thermal_to_process_heat_load_series_mmbtu_per_hour"    => "RGBA(178, 34, 34, 1.0)",    # firebrick
    )
    colors["ASHPSpaceHeater"] = Dict(
        "thermal_to_storage_series_mmbtu_per_hour"  => "RGBA(173, 216, 230, 1.0)",  # lightblue
        "thermal_to_load_series_mmbtu_per_hour"     => "RGBA(70, 130, 180, 1.0)",   # steelblue
    )
    colors["ASHPWaterHeater"] = Dict(
        "thermal_to_storage_series_mmbtu_per_hour"  => "RGBA(176, 224, 230, 1.0)",  # powderblue
        "thermal_to_load_series_mmbtu_per_hour"     => "RGBA(100, 149, 237, 1.0)",  # cornflowerblue
    )

    # Define the start and end time for the date and time array
    start_time = DateTime(year, 1, 1, 0, 0, 0)
    end_time = DateTime(year+1, 1, 1, 0, 0, 0)

    # Create the date and time array with the specified time interval
    dr = start_time:check_time_interval(bau_heating_load):end_time
    dr_v = collect(dr) 
    pop!(dr_v) # pop removes last ts

    ### REopt Data Plotting Begins
    ### BAU Electric Load Line Plot
    # Dotted line for BAU heating load
    push!(traces, scatter(;
        name = "BAU Heating Load",
        x = dr_v,
        y = bau_heating_load,
        mode = "lines",
        fill = nothing,
        line=attr(width=1, color="black", dash="dot")
    ))
    # Sum all series that contain "thermal_to_load_series_mmbtu_per_hour" or "storage_to_load_series_mmbtu_per_hour" to get total electric load line plot
    total_load = sum(
        get(d[tech], "thermal_to_load_series_mmbtu_per_hour", zeros(length(dr_v))) +
        get(d[tech], "storage_to_load_series_mmbtu_per_hour", zeros(length(dr_v)))
        for tech in keys(colors) if haskey(d, tech) && 
            (haskey(d[tech], "thermal_to_load_series_mmbtu_per_hour") || haskey(d[tech], "storage_to_load_series_mmbtu_per_hour")) && 
            (!isempty(get(d[tech], "thermal_to_load_series_mmbtu_per_hour", [])) || !isempty(get(d[tech], "storage_to_load_series_mmbtu_per_hour", []))) && 
            (sum(get(d[tech], "thermal_to_load_series_mmbtu_per_hour", [0.0])) != 0.0 || sum(get(d[tech], "storage_to_load_series_mmbtu_per_hour", [0.0])) != 0.0)
    )
    push!(traces, scatter(;
        name = "Total Heating Load",
        x = dr_v,
        y = total_load,
        mode = "lines",
        fill = nothing,
        line=attr(width=1, color="black")
    ))

    if length(other_timeseries) > 0
        push!(traces, scatter(
                name = other_timeseries_name,
                x = dr_v,
                y = other_timeseries,
                yaxis="y2",
                line = attr(
                    dash= "dashdot",
                    width = 1
                ),
                marker = attr(
                    color="rgb(100,100,100)"
                ),
            )
        )
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
                title = other_timeseries_units,
                overlaying = "y",
                side = "right"
            ))
    end

    # Plot every existing technology
    cumulative_data = zeros(length(dr_v))
    for tech in keys(colors)
        for key in keys(colors[tech])
            if haskey(d,tech)
                sub_dict = d[tech]
                if haskey(sub_dict, key) && !isempty(sub_dict[key]) && sum(sub_dict[key]) != 0.0
                            
                    #invisble line for plotting
                    push!(traces, scatter(
                        name = "invisible",			
                        x = dr_v,
                        y = cumulative_data,
                        mode = "lines",
                        fill = nothing,
                        line = attr(width = 0),
                        showlegend = false,
                        hoverinfo = "skip",
                    )) 

                    new_data = sub_dict[key] 
                    cumulative_data = cumulative_data .+ new_data

                    if contains(key, "to_load")
                        txt = "To Load"
                    elseif contains(key, "to_steamturbine")
                        txt = "To Steam Turbine"
                    elseif contains(key, "to_absorption_chiller")
                        txt = "To Absorption Chiller"
                    elseif contains(key, "to_dhw_load")
                        txt = "To DHW Load"
                    elseif contains(key, "to_space_heating_load")
                        txt = "To Space Heating Load"
                    elseif contains(key, "to_process_heat_load")
                        txt = "To Process Heat Load"
                    elseif contains(key, "to_storage")
                        txt = "Charging Storage"
                    elseif contains(key, "to_high_temp_thermal_storage")
                        txt = "Charging High Temp Storage"
                    elseif contains(key, "curtailed")
                        txt = "Curtailed"
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

    p = plot(traces, layout)

    if save_html
        savefig(p, replace(title, " " => "_") * ".html")
    end

    plot(traces, layout) 
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