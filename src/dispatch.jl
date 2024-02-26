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
###REoptPlots
# Main function to plot electric dispatch
# function plot_electric_dispatch2(d::Dict; title ="Electric Systems Dispatch", save_html=false, display_stats=false, year=2022, save_dispatch_data=false)
#     # Function to flatten nested dictionaries
# 	function flatten_dict(d, prefix_delim = ".")
# 		new_d =   empty(d)
# 		for (key, value) in pairs(d)
# 			if isa(value, Dict)
# 					flattened_value =   flatten_dict(value, prefix_delim)
# 				 for (ikey, ivalue) in pairs(flattened_value)
# 						new_d["$key.$ikey"] =   ivalue
# 				 end
# 			else
# 				new_d[key] =   value
# 			end
# 		end
# 		return new_d
# 	end
#     # Function to check time interval based on array length
# 	function check_time_interval(arr::Array)
# 		if     length(arr) ==   8760
# 		       interval     =   Dates.Hour(1)
# 		elseif length(arr) ==   17520
# 		       interval     =   Dates.Minute(30)
# 		elseif length(arr) ==   35040
# 		       interval     =   Dates.Minute(15)
# 		else
# 			error("Time interval length for one full year must be either 8760 (1-hour), 17520 (30-minutes), or 35040 (15-minutes)")
# 		end
# 		return interval
# 	end
#     # Flatten dictionary and extract dat
# 	df_stat =   flatten_dict(d)
# 	load    =   get(df_stat,"ElectricLoad.load_series_kw","-")
# 	y_max   =   round(maximum(load))*1.8
#     # Initialize traces and layout for plotting
#     traces =   GenericTrace[]
#     layout =   Layout(
#         width            =   1280,
#         height           =   720,
#         hovermode        =   "closest",
#         hoverlabel_align =   "left",
#         plot_bgcolor     =   "white",
#         paper_bgcolor    =   "white",
#         font_size        =   18,
#         xaxis            =   attr(showline=true, ticks="outside", showgrid=true,
#             gridcolor =   "rgba(128, 128, 128, 0.2)", griddash =   "dot",
#             linewidth =   1.5,                        zeroline =   false),
#         yaxis=attr(showline=true, ticks="outside", showgrid=true,
#             gridcolor =   "rgba(128, 128, 128, 0.2)", griddash =   "dot",
#             linewidth =   1.5,                        zeroline =   false, range =   [0, y_max]),
# 		title                     =   title,
# 		xaxis_title               =   "",
# 		yaxis_title               =   "Power (kW)",
# 		xaxis_rangeslider_visible =   true,
# 		legend                    =   attr(x=1.0, y=1.0, xanchor="right", yanchor="top", font=attr(size=14,color="black"),
# 		bgcolor="rgba(255, 255, 255, 0.5)", bordercolor="rgba(128, 128, 128, 0.2)", borderwidth=1),
# 				)
    
#     eload =   d["ElectricLoad"]["load_series_kw"]

#     #Define year
#     year =   year

#     # Define the start and end time for the date and time array
#     start_time =   DateTime(year, 1, 1, 0, 0, 0)
#     end_time   =   DateTime(year+1, 1, 1, 0, 0, 0)

#     # Create the date and time array with the specified time interval
#     dr   =   start_time:check_time_interval(eload):end_time
#     dr_v =   collect(dr)

#     #remove the last value of the array to match array sizes
#     pop!(dr_v)

#     ### REopt Data Plotting Begins
#     ### Total Electric Load Line Plot

#     push!(traces, scatter(;
#         name =   "Total Electric Load",
#         x    =   dr_v,
#         y    =   d["ElectricLoad"]["load_series_kw"],
#         mode =   "lines",
#         fill =   "none",
#         line =   attr(width=1, color="#003f5c")
#     ))

#     dispatch_data =   DataFrame(column1 = String[], column2 = Vector{Any}[])
#     push!(dispatch_data,["Date",dr_v])
#     push!(dispatch_data,["Total Electric Load",d["ElectricLoad"]["load_series_kw"]])

#     ### Grid to Load Plot
#     push!(traces, scatter(;
#         name =   "Grid Serving Load",
#         x    =   dr_v,
#         y    =   d["ElectricUtility"]["electric_to_load_series_kw"],
#         mode =   "lines",
#         fill =   "tozeroy",
#         line =   attr(width=0, color="#0000ff")
#     ))
#     push!(dispatch_data,["Grid Serving Load",d["ElectricUtility"]["electric_to_load_series_kw"]])

#     tech_color_dict     = Dict("PV" => "#ffbb00", "ElectricStorage" => "#e604b3", "Generator" => "#ff552b", "Wind" => "#70ce57", "CHP" => "#33783f", "GHP" => "#52e9e6")
#     tech_names  	    = ["PV","ElectricStorage","Generator","Wind","CHP","GHP"]
#     net_tech_color_dict = Dict("PV" => "#5a1b00", "Wind" => "#003a00")
#     gradient_colors     = []
#     gradient_net_colors = []
#     #Plot every existing technology
#     cumulative_data = zeros(length(dr_v))
#     cumulative_data = cumulative_data .+ d["ElectricUtility"]["electric_to_load_series_kw"]
    
#     #################################################################
#     ########################### Main loop ###########################
    
#     for tech in tech_names
#         already_plotted = false
#         if haskey(d, tech)
#             # Check the type of d[tech]
#             if typeof(d[tech]) == Dict{String, Any}
#                 d[tech] = [d[tech]] 
#             end

#             if tech == "ElectricStorage"
#                 # Existing logic for Electric Storage
#                 new_data = d[tech][1]["storage_to_load_series_kw"]
#                 # println(new_data) 
#                 if isempty(new_data)
#                     # println("Data is empty")
#                     continue
#                 end
#                 ### Battery SOC line plot
#                 push!(traces, scatter(
#                     name = tech * " State of Charge",
#                     x = dr_v,
#                     y = d["ElectricStorage"][1]["soc_series_fraction"] * 100,
#                     yaxis="y2",
#                     line = attr(
#                     dash= "dashdot",
#                     width = 1
#                     ),
#                     marker = attr(
#                         color="rgb(100,100,100)"
#                     ),
#                 ))
#                 push!(dispatch_data,[tech * " State of Charge",new_data])
#                 layout = Layout(
# 					hovermode="closest",
# 					hoverlabel_align="left",
# 					plot_bgcolor="white",
# 					paper_bgcolor="white",
# 					font_size=18,
# 					xaxis=attr(showline=true, ticks="outside", showgrid=true,
# 						gridcolor="rgba(128, 128, 128, 0.2)",griddash= "dot",
# 						linewidth=1.5, zeroline=false),
# 					yaxis=attr(showline=true, ticks="outside", showgrid=true,
# 						gridcolor="rgba(128, 128, 128, 0.2)",griddash= "dot",
# 						linewidth=1.5, zeroline=false, range = [0, y_max]),
#                     # yaxis=attr(showline=true, ticks="outside", showgrid=false,
#                     #     linewidth=1.5, zeroline=false, range = [0, y_max]),
#                     xaxis_title = "",
#                     yaxis_title = "Power (kW)",
#                     xaxis_rangeslider_visible=true,
# 					legend=attr(x=1.0, y=1.0, xanchor="right", yanchor="top", font=attr(size=14,color="black"),
# 					bgcolor="rgba(255, 255, 255, 0.5)", bordercolor="rgba(128, 128, 128, 0.2)", borderwidth=1),
# 					    yaxis2 = attr(
#                         title = "State of Charge (Percent)",
#                         overlaying = "y",
#                         side = "right",
# 						range = [0, 100]
#                     ))

#             elseif tech == "PV" || tech == "Wind"
#                 for (idx, instance) in enumerate(d[tech])
#                     # Now instance will always be a Dict{String, Any}, not a Pair{String, Any}
#                     new_data = instance["electric_to_load_series_kw"]
#                     instance_name = get(instance, "name", tech)
#                     # Only append instance_name if it's different from tech
#                     full_name = tech

#                     if instance_name != tech
#                         full_name *= '-' * instance_name
#                     end

#                     if length(d[tech]) > 1
#                         if idx == 1
#                             gradient_colors = generate_gradient(tech_color_dict[tech], length(d[tech]))
#                         end
#                         color_to_use = gradient_colors[idx]
#                     else
#                         color_to_use = tech_color_dict[tech]
#                     end

#                     if any(x -> x > 0, new_data)
#                         # Invisible line for plotting
#                         push!(traces, scatter(
#                             name = "invisible",
#                             x = dr_v,
#                             y = cumulative_data,
#                             mode = "lines",
#                             fill = Nothing,
#                             line = attr(width = 0),
#                             showlegend = false,
#                             hoverinfo = "skip"
#                         ))

#                         cumulative_data = cumulative_data .+ new_data

#                         # Plot each instance
#                         push!(traces, scatter(
#                             name = full_name * " Serving Load",
#                             x = dr_v,
#                             y = cumulative_data,
#                             mode = "lines",
#                             fill = "tonexty",
#                             line = attr(width=0, color = color_to_use)
#                         ))
#                     end
#                     push!(dispatch_data,[full_name * " Serving Load",new_data])
#                     # After plotting, set the flag to true
#                     already_plotted = true
#                 end

#             else
#                 new_data = d[tech][1]["electric_to_load_series_kw"]
#             end
                
#             if !already_plotted && any(x -> x > 0, new_data)
#                 # Invisible line for plotting
#                 push!(traces, scatter(
#                     name = "invisible",
#                     x = dr_v,
#                     y = cumulative_data,
#                     mode = "lines",
#                     fill = Nothing,
#                     line = attr(width = 0),
#                     showlegend = false,
#                     hoverinfo = "skip"
#                 ))

#                 cumulative_data = cumulative_data .+ new_data

#                 # Plot each technology
#                 push!(traces, scatter(
#                     name = tech * " Serving Load",
#                     x = dr_v,
#                     y = cumulative_data,
#                     mode = "lines",
#                     fill = "tonexty",
#                     line = attr(width=0, color = tech_color_dict[tech])
#                 ))

#                 push!(dispatch_data,[tech * " Serving Load",new_data])
#             end
#         end
#     end
#     #################################################################
#     ########################### Net Metering Enabled ################
#     for tech in tech_names
#         if haskey(d, tech)

#             # Check the type of d[tech]
#             if typeof(d[tech]) == Dict{String, Any}
#                 d[tech] = [d[tech]]  # If it's a single dictionary, convert it to an array containing that dictionary
#             end

#             if tech == "PV" || tech == "Wind"  # Special handling for net metering PV and Wind, can add additional like this || tech == "CHP"
#                 for (idx, instance) in enumerate(d[tech])
#                     new_data = instance["electric_to_grid_series_kw"]
#                     instance_name = get(instance, "name", tech)  # Default to 'tech' if 'name' is not present
#                     # Only append instance_name if it's different from tech
#                     full_name = tech
#                     if instance_name != tech
#                         full_name *= '-' * instance_name
#                     end
#                     if length(d[tech]) > 1  # Multiple instances
#                         if idx == 1  # First instance, use base color
#                             color_to_use = net_tech_color_dict[tech]
#                         else  # Other instances, use gradient
#                             if idx == 2  # Generate gradient colors only when you reach the second instance
#                                 gradient_net_colors = generate_gradient(net_tech_color_dict[tech], length(d[tech]) - 1)  # One fewer than the number of instances
#                             end
#                             color_to_use = gradient_net_colors[idx - 1]  # Use idx - 1 because gradient starts from the second instance
#                         end
#                     else  # Single instance
#                         color_to_use = net_tech_color_dict[tech]
#                     end

#                     if any(x -> x > 0, new_data)
#                         # Invisible line for plotting
#                         push!(traces, scatter(
#                             name = "invisible",
#                             x = dr_v,
#                             y = cumulative_data,
#                             mode = "lines",
#                             fill = Nothing,
#                             line = attr(width = 0),
#                             showlegend = false,
#                             hoverinfo = "skip"
#                         ))

#                         cumulative_data = cumulative_data .+ new_data

#                         # Plot each instance exporting to the grid
#                         push!(traces, scatter(
#                             name = full_name * " Exporting to Grid (NEM)",
#                             x = dr_v,
#                             y = cumulative_data,
#                             mode = "lines",
#                             fill = "tonexty",
#                             line = attr(width=0, color = color_to_use)
#                         ))
#                         push!(dispatch_data,[full_name * " Exporting to Grid (NEM)",new_data])
#                     end
#                 end
#             end
#         end
#     end
#     #################################################################
#     ########################### End Main loop #######################
#     #################################################################
#   	# Plot the minimum, maximum, and average power values.
# 	if display_stats
#         ###Plot Stats
#         avg_val =   round(mean(load),digits=0)
#         max_val =   round(maximum(load),digits=0)
#         min_val =   round(minimum(load),digits=0)

#         x_stat  =   [first(dr_v),dr_v[end-100]]
#         y_stat1 =   [min_val,min_val]
#         y_stat2 =   [max_val,max_val]
#         y_stat3 =   [avg_val,avg_val]


#         push!(traces, scatter(
#         x           =   x_stat,
#         y           =   y_stat1,
#         showlegend  =   false,
#         legendgroup =   "group2",
#         line        =   attr(color="grey", width=1.5,
#                                 dash="dot"),
#         mode         =   "lines+text",
#         name         =   String("Min = $(min_val) kW"),
#         text         =   [String("Min = $(min_val) kW")],
#         textposition =   "Top left"
#             )
#         )

#         push!(traces, scatter(
#         x           =   x_stat,
#         y           =   y_stat2,
#         showlegend  =   false,
#         legendgroup =   "group2",
#         line        =   attr(color="grey", width=1.5,
#                                 dash="dot"),
#         mode         =   "lines+text",
#         name         =   String("Max = $(max_val) kW"),
#         text         =   [String("Max = $(max_val) kW")],
#         textposition =   "Top left"
#             )
#         )

#         push!(traces, scatter(
#         x           =   x_stat,
#         y           =   y_stat3,
#         showlegend  =   false,
#         legendgroup =   "group2",
#         line        =   attr(color="grey", width=1.5,
#                                 dash="dot"),
#         mode         =   "lines+text",
#         name         =   String("Avg = $(avg_val) kW"),
#         text         =   [String("Avg = $(avg_val) kW")],
#         textposition =   "Top left"
#               )
#         )
#     end

#     p =   plot(traces, layout)

#     if save_html
#         savefig(p, replace(title, " " => "_") * ".html")
#     end

#     # Save dispatch data as CSV and JSON if enabled
# 	if save_dispatch_data 
#         # Extract the column names
#         columnNames =   dispatch_data[!,"column1"]
#         # Extract the column values
#         columnValues =   dispatch_data[!,"column2"]
#         # Transpose the data
#         rowData =   hcat(columnValues...)
#         # Create a DataFrame with column names
#         df =   DataFrame(rowData, Symbol.(columnNames))

#         # Save the DataFrame to a CSV file
#         CSV.write("$title-dispatch.csv", df)
# 		JSON3.write("$title-dispatch.json",df)
# 	end

#     # Final rendering of the plot
#     plot(traces, layout)  # will not produce plot in a loop
# end

# function generate_gradient(base_color, num_colors)
#     # Base color in RGB form
#     r, g, b = parse(Int, base_color[2:3], base=16), parse(Int, base_color[4:5], base=16), parse(Int, base_color[6:7], base=16)
#     # RGB for white
#     r_white, g_white, b_white = 255, 255, 255
#     # Generate gradient colors
#     gradient_colors = []
#     for i in 1:num_colors
#         factor = i / num_colors  # Removed "+ 1" to make the gradient steeper
#         new_r = round(Int, r + factor * (r_white - r))
#         new_g = round(Int, g + factor * (g_white - g))
#         new_b = round(Int, b + factor * (b_white - b))
#         push!(gradient_colors, string("#", string(new_r, base=16, pad=2), string(new_g, base=16, pad=2), string(new_b, base=16, pad=2)))
#     end
#     return gradient_colors
# end

function plot_electric_dispatch(d::Dict; title ="Electric Systems Dispatch", save_html=false, year=2022, start_idx = nothing, end_idx = nothing)

    timestep = Int(60/(length(d["ElectricLoad"]["load_series_kw"])/8760))
    @warn "Timestep is [minutes] " timestep

    if isnothing(end_idx)
        start_idx = 1
        end_idx = 8760*Int(60/timestep)
    end
    
    daterange = DateTime(year,1,1):Dates.Minute(timestep):DateTime(year,12,31,23,59)

    pv_to_load = zeros(length(daterange))
    pv_to_grid_export = zeros(length(daterange))
    pv_to_batt_charge = zeros(length(daterange))
    pv_to_curtailment = zeros(length(daterange))

    if typeof(d["PV"]) <: Dict
        pv_to_load = d["PV"]["electric_to_load_series_kw"]
        pv_to_grid_export = d["PV"]["electric_to_grid_series_kw"]
        pv_to_batt_charge = d["PV"]["electric_to_storage_series_kw"]
        pv_to_curtailment = d["PV"]["electric_curtailed_series_kw"]
    else
        # PV is a vector.
        for pv in d["PV"]
            pv_to_load .+= pv["electric_to_load_series_kw"]
            pv_to_grid_export .+= pv["electric_to_grid_series_kw"]
            pv_to_batt_charge .+= pv["electric_to_storage_series_kw"]
            pv_to_curtailment .+= pv["electric_curtailed_series_kw"]
        end
    end

    if haskey(d, "ElectricStorage")
        if d["ElectricStorage"]["size_kw"] == 0.0
            d["ElectricStorage"]["soc_series_fraction"] = zeros(length(daterange))
            d["ElectricStorage"]["storage_to_load_series_kw"] = zeros(length(daterange))
        end
    end

    p = (
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = d["ElectricLoad"]["load_series_kw"][start_idx:end_idx],
            mode="lines",
            line = (
                width = 2,
                color = "black"
            ),
            name = "Site load"
        )
    )(
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = d["ElectricUtility"]["electric_to_load_series_kw"][start_idx:end_idx],
            fill = "tozeroy",
            mode="none",
            fillpattern = (
                bgcolor = "white",
                fgcolor = "black",
                shape = ".",
                size = 6,
                solidity = 0.1
            ),
            stackgroup= "one",
            name = "Grid serving load"
        )
    )(
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = d["ElectricStorage"]["storage_to_load_series_kw"][start_idx:end_idx],
            fill = "tonexty",
            mode="none",
            stackgroup= "one",
            name= "Batt. serving load"
        )
    )(
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = pv_to_load[start_idx:end_idx],
            fill = "tonexty",
            mode="none",
            stackgroup= "one",
            name= "PV serving load"
        )
    )(
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = pv_to_grid_export[start_idx:end_idx],
            fill = "tonexty",
            mode="none",
            stackgroup= "one",
            name= "PV to grid export"
        )
    )(
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = pv_to_batt_charge[start_idx:end_idx],
            fill = "tonexty",
            mode="none",
            stackgroup= "one",
            name= "PV charging batt."
        )
    )(
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = pv_to_curtailment[start_idx:end_idx],
            fill = "tonexty",
            mode="none",
            stackgroup= "one",
            name= "PV curtailed"
        )
    )(
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = d["ElectricUtility"]["electric_to_storage_series_kw"][start_idx:end_idx],
            fill = "tonexty",
            mode="none",
            stackgroup= "one",
            name= "Grid charge batt."
        )
    )(
        plot.scatter(;
            x = daterange[start_idx:end_idx],
            y = d["ElectricStorage"]["soc_series_fraction"][start_idx:end_idx],
            mode="lines",
            name= "Batt. SoC",
            yaxis = "y2",
            line = (
                color = "grey",
                dash = "dash"
            )
        )
    )

    p.layout.title.text = title
    p.layout.hovermode = "x unified"
    p.layout.xaxis.title.text = "Timestep"
    p.layout.yaxis.title.text = "Power [kW]"
    p.layout.yaxis2.title = "Battery state of charge (SoC) [%]"
    p.layout.yaxis2.overlaying = "y"
    p.layout.yaxis2.side = "right"
    p.layout.yaxis2.range = [-5.0, 1.25]
    p.layout.yaxis2.showgrid = false
    p.layout.yaxis2.zeroline = false
    p.layout.yaxis2.showticklabels = false

    if save_html
        PlotlyLight.save(p, string(title, ".html"))
    end

    nothing
end