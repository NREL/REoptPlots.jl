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
function plot_electric_dispatch(d::Dict; title ="Electric Systems Dispatch", save_html=false, display_stats=false, year=2022, save_dispatch_data=false)
    # Function to flatten nested dictionaries
	function flatten_dict(d, prefix_delim = ".")
		new_d =   empty(d)
		for (key, value) in pairs(d)
			if isa(value, Dict)
					flattened_value =   flatten_dict(value, prefix_delim)
				 for (ikey, ivalue) in pairs(flattened_value)
						new_d["$key.$ikey"] =   ivalue
				 end
			else
				new_d[key] =   value
			end
		end
		return new_d
	end
    # Function to check time interval based on array length
	function check_time_interval(arr::Array)
		if     length(arr) ==   8760
		       interval     =   Dates.Hour(1)
		elseif length(arr) ==   17520
		       interval     =   Dates.Minute(30)
		elseif length(arr) ==   35040
		       interval     =   Dates.Minute(15)
		else
			error("Time interval length must be either 8760, 17520, or 35040")
		end
		return interval
	end
    # Flatten dictionary and extract dat
	df_stat =   flatten_dict(d)
	load    =   get(df_stat,"ElectricLoad.load_series_kw","-")
	y_max   =   round(maximum(load))*1.8
    # Initialize traces and layout for plotting
    traces =   GenericTrace[]
    layout =   Layout(
        width            =   1280,
        height           =   720,
        hovermode        =   "closest",
        hoverlabel_align =   "left",
        plot_bgcolor     =   "white",
        paper_bgcolor    =   "white",
        font_size        =   18,
        xaxis            =   attr(showline=true, ticks="outside", showgrid=true,
            gridcolor =   "rgba(128, 128, 128, 0.2)", griddash =   "dot",
            linewidth =   1.5,                        zeroline =   false),
        yaxis=attr(showline=true, ticks="outside", showgrid=true,
            gridcolor =   "rgba(128, 128, 128, 0.2)", griddash =   "dot",
            linewidth =   1.5,                        zeroline =   false, range =   [0, y_max]),
		title                     =   title,
		xaxis_title               =   "",
		yaxis_title               =   "Power (kW)",
		xaxis_rangeslider_visible =   true,
		legend                    =   attr(x=1.0, y=1.0, xanchor="right", yanchor="top", font=attr(size=14,color="black"),
		bgcolor="rgba(255, 255, 255, 0.5)", bordercolor="rgba(128, 128, 128, 0.2)", borderwidth=1),
				)
    
    eload =   d["ElectricLoad"]["load_series_kw"]

    #Define year
    year =   year

    # Define the start and end time for the date and time array
    start_time =   DateTime(year, 1, 1, 0, 0, 0)
    end_time   =   DateTime(year+1, 1, 1, 0, 0, 0)

    # Create the date and time array with the specified time interval
    dr   =   start_time:check_time_interval(eload):end_time
    dr_v =   collect(dr)

    #remove the last value of the array to match array sizes
    pop!(dr_v)

    ### REopt Data Plotting Begins
    ### Total Electric Load Line Plot

    push!(traces, scatter(;
        name =   "Total Electric Load",
        x    =   dr_v,
        y    =   d["ElectricLoad"]["load_series_kw"],
        mode =   "lines",
        fill =   "none",
        line =   attr(width=1, color="#003f5c")
    ))

    dispatch_data =   DataFrame(column1 = String[], column2 = Vector{Any}[])
    push!(dispatch_data,["Date",dr_v])
    push!(dispatch_data,["Total Electric Load",d["ElectricLoad"]["load_series_kw"]])

    ### Grid to Load Plot
    push!(traces, scatter(;
        name =   "Grid Serving Load",
        x    =   dr_v,
        y    =   d["ElectricUtility"]["electric_to_load_series_kw"],
        mode =   "lines",
        fill =   "tozeroy",
        line =   attr(width=0, color="#0000ff")
    ))
    push!(dispatch_data,["Grid Serving Load",d["ElectricUtility"]["electric_to_load_series_kw"]])


 tech_color_dict =   Dict("PV" => "#fea600", "ElectricStorage" => "#e604b3", "Generator" => "#ff552b", "Wind" => "#70ce57", "CHP" => "#33783f", "GHP" => "#52e9e6")
 tech_names      =   ["PV","ElectricStorage","Generator","Wind","CHP","GHP"]

    #Plot every existing technology

    cumulative_data =   zeros(length(dr_v))
    cumulative_data =   cumulative_data .+ d["ElectricUtility"]["electric_to_load_series_kw"]


    for tech in tech_names
        if haskey(d, tech)
               sub_dict  =   d[tech]
            if tech     ==   "ElectricStorage"
               new_data  =   sub_dict["storage_to_load_series_kw"]
				if isempty(new_data)
					continue
				end
                ### Battery SOC line plot
                push!(traces, scatter(
                    name  =   "Battery State of Charge",
                    x     =   dr_v,
                    y     =   d["ElectricStorage"]["soc_series_fraction"]*100,
                    yaxis =   "y2",
                    line  =   attr(
                    dash  =   "dashdot",
                    width =   1
                    ),
                    marker = attr(
                        color =   "rgb(100,100,100)"
                    ),
                ))

                push!(dispatch_data,["Battery State of Charge",new_data])


                layout = Layout(
					width            =   1280,
					height           =   720,
					hovermode        =   "closest",
					hoverlabel_align =   "left",
					plot_bgcolor     =   "white",
					paper_bgcolor    =   "white",
					font_size        =   18,
					xaxis            =   attr(showline=true, ticks="outside", showgrid=true,
						gridcolor =   "rgba(128, 128, 128, 0.2)", griddash =   "dot",
						linewidth =   1.5,                        zeroline =   false),
					yaxis=attr(showline=true, ticks="outside", showgrid=true,
						gridcolor =   "rgba(128, 128, 128, 0.2)", griddash =   "dot",
						linewidth =   1.5,                        zeroline =   false, range =   [0, y_max]),
					xaxis_title               =   "",
					yaxis_title               =   "Power (kW)",
					xaxis_rangeslider_visible =   true,
					legend                    =   attr(x=1.0, y=1.0, xanchor="right", yanchor="top", font=attr(size=14,color="black"),
					bgcolor="rgba(255, 255, 255, 0.5)", bordercolor="rgba(128, 128, 128, 0.2)", borderwidth=1),
					    yaxis2 = attr(
						title      =   "State of Charge (Percent)",
						overlaying =   "y",
						side       =   "right",
						range      =   [0, 100]
                    ))
            else
                new_data =   sub_dict["electric_to_load_series_kw"]
            end
            if any(x -> x > 0, new_data)
				#invisble line for plotting
				push!(traces, scatter(
					name       =   "invisible",
					x          =   dr_v,
					y          =   cumulative_data,
					mode       =   "lines",
					fill       =   Nothing,
					line       =   attr(width = 0),
					showlegend =   false,
					hoverinfo  =   "skip",
				))

				cumulative_data =   cumulative_data .+ new_data
				
				#plot each technology
				push!(traces, scatter(;
					name =   tech * " Serving Load",
					x    =   dr_v,
					y    =   cumulative_data,
					mode =   "lines",
					fill =   "tonexty",
					line =   attr(width=0, color = tech_color_dict[tech]),
				))
                push!(dispatch_data,[tech * " Serving Load",new_data])

        
			end
        end
	end

	net_tech_color_dict =   Dict("PV" => "#326f9c", "Wind" => "#c2c5e2")

	#Net Metering Enabled
	for tech in tech_names
        if haskey(d, tech)
				   sub_dict  =   d[tech]
				if tech     ==   "PV" || tech ==   "Wind"
				   new_data  =   sub_dict["electric_to_grid_series_kw"]
				if any(x -> x > 0, new_data)
					#invisble line for plotting
					push!(traces, scatter(
						name       =   "invisible",
						x          =   dr_v,
						y          =   cumulative_data,
						mode       =   "lines",
						fill       =   Nothing,
						line       =   attr(width = 0),
						showlegend =   false,
						hoverinfo  =   "skip"
                        )) 

					cumulative_data =   cumulative_data .+ new_data
				
					#plot each technology
					push!(traces, scatter(;
						name =   tech * " Exporting to Grid",
						x    =   dr_v,
						y    =   cumulative_data,
						mode =   "lines",
						fill =   "tonexty",
						line =   attr(width=0, color = net_tech_color_dict[tech]),
					))        
                    push!(dispatch_data,[tech * " Exporting to Grid",new_data])

				else
					#donothing
				end
			end 
		end
	end
	
  	# Plot the minimum, maximum, and average power values.
	if display_stats
        ###Plot Stats
        avg_val =   round(mean(load),digits=0)
        max_val =   round(maximum(load),digits=0)
        min_val =   round(minimum(load),digits=0)

        x_stat  =   [first(dr_v),dr_v[end-100]]
        y_stat1 =   [min_val,min_val]
        y_stat2 =   [max_val,max_val]
        y_stat3 =   [avg_val,avg_val]


        push!(traces, scatter(
        x           =   x_stat,
        y           =   y_stat1,
        showlegend  =   false,
        legendgroup =   "group2",
        line        =   attr(color="grey", width=1.5,
                                dash="dot"),
        mode         =   "lines+text",
        name         =   String("Min = $(min_val) kW"),
        text         =   [String("Min = $(min_val) kW")],
        textposition =   "Top left"
            )
        )

        push!(traces, scatter(
        x           =   x_stat,
        y           =   y_stat2,
        showlegend  =   false,
        legendgroup =   "group2",
        line        =   attr(color="grey", width=1.5,
                                dash="dot"),
        mode         =   "lines+text",
        name         =   String("Max = $(max_val) kW"),
        text         =   [String("Max = $(max_val) kW")],
        textposition =   "Top left"
            )
        )

        push!(traces, scatter(
        x           =   x_stat,
        y           =   y_stat3,
        showlegend  =   false,
        legendgroup =   "group2",
        line        =   attr(color="grey", width=1.5,
                                dash="dot"),
        mode         =   "lines+text",
        name         =   String("Avg = $(avg_val) kW"),
        text         =   [String("Avg = $(avg_val) kW")],
        textposition =   "Top left"
              )
        )
    end

    p =   plot(traces, layout)

    if save_html
        savefig(p, replace(title, " " => "_") * ".html")
    end

    # Save dispatch data as CSV and JSON if enabled
	if save_dispatch_data 
        # Extract the column names
        columnNames =   dispatch_data[!,"column1"]
        # Extract the column values
        columnValues =   dispatch_data[!,"column2"]
        # Transpose the data
        rowData =   hcat(columnValues...)
        # Create a DataFrame with column names
        df =   DataFrame(rowData, Symbol.(columnNames))

        # Save the DataFrame to a CSV file
        CSV.write("$title-dispatch.csv", df)
		JSON3.write("$title-dispatch.json",df)
	end

    # Final rendering of the plot
    plot(traces, layout)  # will not produce plot in a loop
end