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

# Define an empty array to store data arrays
arrays = []

function plot_electric_dispatch(dict::Dict; title="Electric Systems Dispatch", save_html=true)
    keys = ["PV","ElectricStorage","Generator","Wind","CHP","GHP"]
    names = ["electric_to_load_series_kw", "storage_to_load_series_kw"]
    dr = DateTime(2017,1,1,0,0,0):Dates.Hour(1):DateTime(2018,1,1,0,0,0)
    dr_v = collect(dr)   

    traces = PlotlyJS.GenericTrace[]
    layout = PlotlyJS.Layout(
        title_text = "Electric Systems Dispatch",
        yaxis_title_text = "Power (kW)",
        )

    ###Plot Stats
    df_stat = rec_flatten_dict(dict)
	load  = get(df_stat,"ElectricLoad.load_series_kw","-")
	avg_val = round(mean(load))
	max_val = round(maximum(load))
	min_val = round(minimum(load))

    x_stat = [first(dr_v),last(dr_v)]
	y_stat1 = [min_val,min_val]
	y_stat2 = [max_val,max_val]
	y_stat3 = [avg_val,avg_val]
    
	push!(traces, PlotlyJS.scatter(
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

	push!(traces, PlotlyJS.scatter(
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

	push!(traces, PlotlyJS.scatter(
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
	
    total_array = []

    ### REopt Data Plotting
    ### Electric Load Line Plot
    push!(traces, PlotlyJS.scatter(
        name = "Total Electric Load",
        x = dr_v,
        y = dict["ElectricLoad"]["load_series_kw"],
        fill = "none",
        line = PlotlyJS.attr(
            width = 1
        ),
        marker = PlotlyJS.attr(
            color="#003f5c",
        )
    ))

    push!(traces, PlotlyJS.scatter(
        name = "Grid Serving Load",
        x = dr_v,
        y = dict["ElectricUtility"]["electric_to_load_series_kw"],
        fill = "tozeroy",
        marker = PlotlyJS.attr(
            color="#0000ff",
        ),
        line = PlotlyJS.attr(
            width = 0
        ),
    ))

    add_array(dict["ElectricUtility"]["electric_to_load_series_kw"])
    total_array = create_total_array()

    color_list = ["#fea600", "#e604b3", "#ff552b", "#70ce57", "#33783f", "#52e9e6", "#326f9c", "#c2c5e2", "#760796"]
    current_color_index = 1

    for key in keys
        if haskey(dict, key)
            sub_dict = get(dict, key, nothing)
            for name in names
                if haskey(sub_dict, name)
                    data_array = get(sub_dict, name, nothing)

                    # Define an empty array to store the data arrays                    
                    #invisible line for stacking
                    push!(traces, PlotlyJS.scatter(
                        name = "invisible",
                        x = dr_v,
                        y = total_array,
                        fill = Nothing,
                        line = PlotlyJS.attr(
                            width = 0
                        ),
                        showlegend = false,
                        hoverinfo = "skip",
                    ))

                    add_array(data_array)
                    total_array = create_total_array()

                    #plot each technology
                    push!(traces, PlotlyJS.scatter(
                        name = key,
                        x = dr_v,
                        y = total_array,
                        fill = "tonexty",
                        marker = PlotlyJS.attr(
                            color=color_list[current_color_index],
                        ),
                        line = PlotlyJS.attr(
                            width = 0),
                        ))
                    
                    current_color_index += 1

                end
            end
        end
    end
    
    p = PlotlyJS.plot(traces, layout)

    if save_html
        PlotlyJS.savefig(p, replace(title, " " => "_") * ".html")
    end

    PlotlyJS.plot(traces, layout)  # will not produce plot in a loop
end