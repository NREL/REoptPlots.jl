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
        legend=attr(x=1.07, y=0.5, font=attr(size=14,color="black")))
    
    tech_names  = ["PV","ElectricStorage","Generator","Wind","CHP","GHP"]
    eload = d["ElectricLoad"]["load_series_kw"]

    # Define the start and end time for the date and time array
    start_time  = DateTime(year, 1, 1, 0, 0, 0)
    end_time    = DateTime(year+1, 1, 1, 0, 0, 0)

    # Create the date and time array with the specified time interval
    dr = start_time:check_time_interval(eload):end_time
    dr_v = collect(dr)

    #remove the last value of the array to match array sizes
    pop!(dr_v)

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
        line=attr(width=1, color="#003f5c")
    ))

    ### Grid to Load Plot
    push!(traces, scatter(;
        name = "Grid to Load",
        x = dr_v,
        y = d["ElectricUtility"]["electric_to_load_series_kw"],
        mode = "lines",
        fill = "tozeroy",
        line = attr(width=0, color="#0000ff")
    ))

    colors_list = ["#fea600", "#e604b3", "#ff552b", "#70ce57", "#33783f", "#52e9e6", "#326f9c", "#c2c5e2", "#760796"]
    current_color_index = 1   

    #Plot every existing technology
    cumulative_data = zeros(length(dr_v))
    cumulative_data = cumulative_data .+ d["ElectricUtility"]["electric_to_load_series_kw"]

    for tech in tech_names
        if haskey(d, tech)
            sub_dict = d[tech]
            if tech == "ElectricStorage"
                new_data = sub_dict["storage_to_load_series_kw"]

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
                    legend=attr(x=1.07, y=0.5, 
                                font=attr(
                                size=14,
                                color="black")
                                ),
                    yaxis2 = attr(
                        title = "State of Charge (Percent)",
                        overlaying = "y",
                        side = "right"
                    ))

            else
                new_data = sub_dict["electric_to_load_series_kw"]
            end
            
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

            cumulative_data = cumulative_data .+ new_data
            
            #plot each technology
            push!(traces, scatter(;
                name = tech* "to Load",
                x = dr_v,
                y = cumulative_data,
                mode = "lines",
                fill = "tonexty",
                line = attr(width=0, color = colors_list[current_color_index])
            ))        
            
            current_color_index += 1
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