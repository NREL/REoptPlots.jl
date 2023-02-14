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
function check_time_interval(arr::Array)
    if length(arr) < 10000
        interval = Dates.Minute(15)
    elseif length(arr) < 100000
        interval = Dates.Minute(30)
    else
        interval = Dates.Hour(1)
    end
    return interval
end


function plot_electric_dispatch(d::Dict; title="Electric Systems Dispatch", save_html=true)
    
    tech_names = ["PV","ElectricStorage","Generator","Wind","CHP","GHP"]

    traces = GenericTrace[]

    eload = d["ElectricLoad"]["load_series_kw"]

    #Define year
    year = 2017
    
    # Define the start and end time for the date and time array
    start_time  = DateTime(year, 1, 1, 0, 0, 0)
    end_time    = DateTime(year+1, 1, 1, 0, 0, 0)

    # Create the date and time array with the specified time interval
    dr_v = collect(start_time:check_time_interval(eload):end_time) 
    
    ### REopt Data Plotting
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
        name = "Grid Serving Load",
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
                name = tech,
                x = dr_v,
                y = cumulative_data,
                mode = "lines",
                fill = "tonexty",
                line = attr(width=0, color = colors_list[current_color_index])
            ))        
            
            current_color_index += 1
        end
    end
    
    layout = PlotlyJS.Layout(
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


    p = plot(traces, layout)

    if save_html
        savefig(p, replace(title, " " => "_") * ".html")
    end

    plot(traces, layout)  # will not produce plot in a loop
end


