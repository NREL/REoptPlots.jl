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
function plot_electric_dispatch(d::Dict{Any, Any}; title="Electric Systems Dispatch", save_html=true)
    

    tech_names = ["PV","ElectricStorage","Generator","Wind","CHP","GHP"]

    all_data = Vector{Dict{String, Vector{Float64}}}(undef, length(dict_names)) 

    traces = GenericTrace[]

    dr = DateTime(2017,1,1,0,0,0):Dates.Hour(1):DateTime(2018,1,1,0,0,0)
    dr_v = collect(dr)
    pop!(dr_v)
    

    ### REopt Data Plotting
    ### Electric Load Line Plot
    push!(traces, scatter(;
        name = "Total Electric Load",
        x = dr_v,
        y = d["ElectricLoad"]["load_series_kw"],
        mode = "lines",
        fill = "none",
        line=attr(width=1, color="#003f5c")
    ))

    ### Grid to Load Fill-In
    push!(traces, scatter(;
        name = "Grid Serving Load",
        x = dr_v,
        y = d["ElectricUtility"]["electric_to_load_series_kw"],
        mode="lines",
        fill = "tozeroy",
        line=attr(width=0, color="#0000ff")
    ))


    # color_list = ["#fea600", "#e604b3", "#ff552b", "#70ce57", "#33783f", "#52e9e6", "#326f9c", "#c2c5e2", "#760796"]
    # current_color_index = 1   
    cumulative_data = zeros(0)
    cumulative_data = [cumulative_data; d["ElectricUtility"]["electric_to_load_series_kw"]]

    for tech in tech_names
        if haskey(nested_dict, tech)
            sub_dict = nested_dict[tech]
            if tech == "ElectricStorage"
                data = sub_dict["storage_to_load_series_kw"]
            else
                data = sub_dict["electric_to_load_series_kw"]
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

            cumulative_data = [cumulative_data; data]
            
            #plot each technology
            push!(traces, scatter(;
                name = a_key,
                x = dr_v,
                y = cumulative_data,
                mode = "lines",
                fill = "tonexty",
                line = attr(width=0)
                ))        
            
        end
    end
    
    layout = Layout(
        title_text = title,
        yaxis_title_text = "Power (kW)",
        )

    p = plot(traces, layout)

    if save_html
        savefig(p, replace(title, " " => "_") * ".html")
    end

    plot(traces, layout)  # will not produce plot in a loop
end