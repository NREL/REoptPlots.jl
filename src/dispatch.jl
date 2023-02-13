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

####BASE###

function plot_electric_dispatch(d::Dict; title="Electric Systems Dispatch", save_html=true)
    keys = ["ElectricUtility","PV","Wind","ElectricStorage","Generator","CHP","GHP"]
    list_names = ["electric_to_load_series_kw", "storage_to_load_series_kw"]
     #Dates Dataframe
    dr = DateTime(2017,1,1,0,0,0):Dates.Hour(1):DateTime(2018,1,1,0,0,0)
    dr_v = collect(dr)    
    data_array = []
    for key in keys
        if haskey(d, key)
            for list_name in list_names
                if haskey(d[key], list_name)
                    new_data_array = d[key][list_name]
                    data_array = vcat(data_array, new_data_array)
                    break
                end
            end
        end
    end
    PlotlyJS.scatter(dr_v, y=data_array[:,2], mode="markers")
end

# function plot_electric_dispatch(d::Dict; title="Electric Systems Dispatch", save_html=true)

# #######################################################################################
# #############################BASE PLOT#################################################
# #######################################################################################
#     traces = PlotlyJS.GenericTrace[]

#     layout = PlotlyJS.Layout(
#         title_text = title,
#         yaxis_title_text = "Power (kW)",
#         )
    
#     #Dates Dataframe
#     dr = DateTime(2017,1,1,0,0,0):Dates.Hour(1):DateTime(2018,1,1,0,0,0)
#     dr_v = collect(dr)
#     pop!(dr_v)
    
#     ###Plot Stats
#     df_stat = rec_flatten_dict(d)
# 	load  = get(df_stat,"ElectricLoad.load_series_kw","-")
# 	avg_val = round(mean(load))
# 	max_val = round(maximum(load))
# 	min_val = round(minimum(load))

#     x_stat = [first(dr_v),dr_v[end-100]]
# 	y_stat1 = [min_val,min_val]
# 	y_stat2 = [max_val,max_val]
# 	y_stat3 = [avg_val,avg_val]
    
# 	push!(traces, PlotlyJS.scatter(
# 	x = x_stat,
# 	y = y_stat1,
# 	showlegend = false,
# 	legendgroup="group2",
# 	line=attr(color="grey", width=0.5,
#                               dash="dot"),
# 	mode="lines+text",
#     name=String("Min = $(min_val) kW"),
#     text=[String("Min = $(min_val) kW")],
#     textposition="top right"
# 		)
# 	)

# 	push!(traces, PlotlyJS.scatter(
# 	x = x_stat,
# 	y = y_stat2,
# 	showlegend = false,
# 	legendgroup="group2",
# 	line=attr(color="grey", width=0.5,
#                               dash="dot"),
# 	mode="lines+text",
#     name=String("Max = $(max_val) kW"),
#     text=[String("Max = $(max_val) kW")],
#     textposition="top right"
# 		)
# 	)

# 	push!(traces, PlotlyJS.scatter(
# 	x = x_stat,
# 	y = y_stat3,
# 	showlegend = false,
# 	legendgroup="group2",
# 	line=attr(color="grey", width=0.5,
#                               dash="dot"),
# 	mode="lines+text",
#     name=String("Avg = $(avg_val) kW"),
#     text=[String("Avg = $(avg_val) kW")],
#     textposition="top right"
# 		)
# 	)
	
#     ### REopt Data Plotting
#     eload = d["ElectricLoad"]["load_series_kw"]
#     T = length(eload)

#     ### Electric Load Line Plot
#     push!(traces, PlotlyJS.scatter(
#         name = "Total Electric Load",
#         x = dr_v,
#         y = d["ElectricLoad"]["load_series_kw"],
#         fill = "none",
#         line = PlotlyJS.attr(
#             width = 0.5
#         ),
#         marker = PlotlyJS.attr(
#             color="#003f5c",
#         )
#     ))

#     ### Grid to Load Fill-In
#     push!(traces, PlotlyJS.scatter(
#         name = "Grid Serving Load",
#         x = dr_v,
#         y = d["ElectricUtility"]["electric_to_load_series_kw"],
#         fill = "tozeroy",
#         marker = PlotlyJS.attr(
#             color="#0000ff",
#         ),
#         line = PlotlyJS.attr(
#             width = 0
#         ),
#     ))

#     ### Invisible line for stacking
#     push!(traces, PlotlyJS.scatter(
#         name = "invisible",
#         x = dr_v,
#         y = d["ElectricUtility"]["electric_to_load_series_kw"],
#         fill = Nothing,
#         line = PlotlyJS.attr(
#             width = 0
#         ),
#         showlegend = false,
#         hoverinfo = "skip",
#     ))

# #######################################################################################
# #######################################################################################
# #######################################################################################
 
# ### PV to load Fill-In
#     pv_to_load = zeros(T)
#     if "PV" in keys(d)  # TODO multiple PVs
#         pv_to_load = d["PV"]["electric_to_load_series_kw"],
#         push!(traces, PlotlyJS.scatter(
#             name = "PV Serving Load",
#             x = dr_v,
#             y = d["PV"]["electric_to_load_series_kw"] .+  d["ElectricUtility"]["electric_to_load_series_kw"],
#             fill = "tonexty",
#             marker = PlotlyJS.attr(
#                 color="#ffa600",
#             ),
#             line = PlotlyJS.attr(
#                 width = 0
#             ),
#         ))

#     end
#     layout = PlotlyJS.Layout(
# 		    hovermode="closest",
#         	hoverlabel_align="left",
# 			plot_bgcolor="white",
# 	        paper_bgcolor="white",
# 		    font_size=18,
#        		xaxis=attr(showline=true, ticks="outside", showgrid=false,
#                    linewidth=1.5, zeroline=false),
#         	yaxis=attr(showline=true, ticks="outside", showgrid=true,
#                    linewidth=1.5, zeroline=false, color="black"),
# 		    title = title,
#             xaxis_title = "",
#             yaxis_title = "Power (kW)",
# 			xaxis_rangeslider_visible=true,
# 			legend=attr(x=1.07, y=0.5, 
# 						font=attr(
# 			            size=14,
# 			            color="black")
# 						)
# 	)

#     ### Battery to load Fill-IN
#     if "ElectricStorage" in keys(d)
#         # invisible line for stacking
#         push!(traces, PlotlyJS.scatter(
#             name = "invisible",			
#             x = dr_v,
# 			y = d["ElectricUtility"]["electric_to_load_series_kw"] .+ d["PV"]["electric_to_load_series_kw"],
#             fill = Nothing,
#             line = PlotlyJS.attr(
#                 width = 0
#             ),
#             showlegend = false,
#             hoverinfo = "skip",
#         ))

#         push!(traces, PlotlyJS.scatter(
#             name = "Battery Serving Load",
#             x = dr_v,
#             y = d["ElectricUtility"]["electric_to_load_series_kw"] .+ d["PV"]["electric_to_load_series_kw"] .+ d["ElectricStorage"]["storage_to_load_series_kw"],
#             fill = "tonexty",
#             marker = PlotlyJS.attr(
#                 color="#e700b3",
#             ),
#             line = PlotlyJS.attr(
#                 width = 0
#             ),
#         ))
#         ### Battery SOC line plot
#         push!(traces, PlotlyJS.scatter(
#             name = "Battery State of Charge",
#             x = dr_v,
#             y = d["ElectricStorage"]["soc_series_fraction"]*100,
#             yaxis="y2",
#             line = PlotlyJS.attr(
#             dash= "dashdot",
#             width = 1
#             ),
#             marker = PlotlyJS.attr(
#                 color="rgb(100,100,100)"
#             ),
#         ))

#         layout = PlotlyJS.Layout(
# 			hovermode="closest",
#         	hoverlabel_align="left",
# 			plot_bgcolor="white",
# 	        paper_bgcolor="white",
# 		    font_size=18,
#        		xaxis=attr(showline=true, ticks="outside", showgrid=false,
#                    linewidth=1.5, zeroline=false),
#         	yaxis=attr(showline=true, ticks="outside", showgrid=false,
#                    linewidth=1.5, zeroline=false),
#             xaxis_title = "",
#             yaxis_title = "Power (kW)",
# 			xaxis_rangeslider_visible=true,
# 			legend=attr(x=1.07, y=0.5, 
# 						font=attr(
# 			            size=14,
# 			            color="black")
# 						),
#             yaxis2 = PlotlyJS.attr(
#                 title = "State of Charge (Percent)",
#                 overlaying = "y",
#                 side = "right"
#             )
			
#         )
#     end

#         ### Generator to load Fill-In
#     if "Generator" in keys(d)
#         # invisible line for stacking
#         push!(traces, PlotlyJS.scatter(
#             name = "invisible",
#             x = dr_v,
#             y = d["ElectricUtility"]["electric_to_load_series_kw"] .+ d["PV"]["electric_to_load_series_kw"] .+ 	d["ElectricStorage"]["storage_to_load_series_kw"], 
#             fill = Nothing,
#             line = PlotlyJS.attr(
#                 width = 0
#             ),
#             showlegend = false,
#             hoverinfo = "skip",
#         ))
				
#         push!(traces, PlotlyJS.scatter(
#             name = "Generator Serving Load",
#             x = dr_v,
# 			y = d["ElectricUtility"]["electric_to_load_series_kw"] .+ d["PV"]["electric_to_load_series_kw"] .+ 	d["ElectricStorage"]["storage_to_load_series_kw"] .+					d["Generator"]["electric_to_load_series_kw"],
#             fill = "tonexty",
#             marker = PlotlyJS.attr(
#                 color="#ff552b",
#             ),
#             line = PlotlyJS.attr(
#                 width = 0
#             ),
#         ))
#     end
#     p = PlotlyJS.plot(traces, layout)

#     if save_html
#         PlotlyJS.savefig(p, replace(title, " " => "_") * ".html")
#     end

#     PlotlyJS.plot(traces, layout)  # will not produce plot in a loop

# end

# function rec_flatten_dict(d, prefix_delim = ".")
#     new_d = empty(d)
#     for (key, value) in pairs(d)
#         if isa(value, Dict)
#              flattened_value = rec_flatten_dict(value, prefix_delim)
#              for (ikey, ivalue) in pairs(flattened_value)
#                  new_d["$key.$ikey"] = ivalue
#              end
#         else
#             new_d[key] = value
#         end
#     end
#     return new_d
# end