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
function plot_electric_dispatch(d::Dict; title="Electric Systems Dispatch", save_html=true)

    # Define an empty array to store data arrays
    total_array = []
    arrays = []

    empty!(arrays)
    empty!(total_array)

    # Function to add a new data array to the existing array
    function add_array(new_array)
        # Check if the new array is a 1-d array
        if ndims(new_array) != 1
            println("Error: Not a 1-d array")
        else
            # Check if the length of the new array matches with existing arrays
            if length(arrays) > 0 && length(new_array) != length(arrays[1])
                println("Error: Length of new array does not match existing arrays")
            else
                # Add the new array to the existing array
                push!(arrays, new_array)
            end
        end
    end

    # Function to create a total array
    function create_total_array()
        if length(arrays) == 0
            println("Error: No arrays found")
        else
            total_array = similar(arrays[1])
            for i in 1:length(arrays)
                total_array = total_array .+ arrays[i]
            end
            return total_array
        end
    end
    
    key_names = ["PV","ElectricStorage","Generator","Wind","CHP","GHP"]
    names = ["electric_to_load_series_kw", "storage_to_load_series_kw"]
    
    traces = GenericTrace[]

    dr = DateTime(2017,1,1,0,0,0):Dates.Hour(1):DateTime(2018,1,1,0,0,0)
    dr_v = collect(dr)
    pop!(dr_v)
    

    ### REopt Data Plotting
    ### Electric Load Line Plot
    push!(traces, scatter(
        name = "Total Electric Load",
        x = dr_v,
        y = d["ElectricLoad"]["load_series_kw"],
        mode = "lines",
        fill = "none",
        line=attr(width=1, color="#003f5c")
    ))

    ### Grid to Load Fill-In
    push!(traces, scatter(
        name = "Grid Serving Load",
        x = dr_v,
        y = d["ElectricUtility"]["electric_to_load_series_kw"],
        mode="lines",
        fill = "tozeroy",
        line=attr(width=0, color="#0000ff")
    ))

    add_array(d["ElectricUtility"]["electric_to_load_series_kw"])
    total_array = create_total_array()
    
    # color_list = ["#fea600", "#e604b3", "#ff552b", "#70ce57", "#33783f", "#52e9e6", "#326f9c", "#c2c5e2", "#760796"]
    # current_color_index = 1

    for a_key in key_names
        if haskey(d, a_key)
            sub_dict = get(d, a_key, nothing)
            for name in names
                if haskey(sub_dict, name)
                    data_array = get(sub_dict, name, nothing)

                    # Define an empty array to store the data arrays                    
                    #invisible line for stacking
                    push!(traces, scatter(
                        name = "invisible",
                        x = dr_v,
                        y = total_array,
                        mode="lines",
                        fill = Nothing,
                        line=attr(width=0),
                        showlegend = false,
                        hoverinfo = "skip"
                    ))

                    add_array(data_array)
                    total_array = create_total_array()

                    #plot each technology
                    push!(traces, scatter(
                        name = a_key,
                        x = dr_v,
                        y = total_array,
                        mode = "lines",
                        fill = "tonexty",
                        line=attr(width=0),
                        ))
                        
                    # current_color_index += 1
                    
                end
            end
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
        legend=attr(x=1.07, y=0.5, font=attr(size=14,color="black"))
        )

    p = plot(traces, layout)

    if save_html
        savefig(p, replace(title, " " => "_") * ".html")
    end

    plot(traces, layout)  # will not produce plot in a loop
end