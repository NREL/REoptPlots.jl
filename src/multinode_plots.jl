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

#=
# Example of an inputs dictionary into the multinode_create_plots function
data_dictionary_for_plots = Dict([
    ("voltage_plot_time_step", 1),
    ("time_steps_for_results_dashboard", time_steps_for_results_dashboard ),
    ("Multinode_Inputs", Multinode_Inputs),
    ("outage_survival_results", outage_survival_results),
    ("outage_start_timesteps_checked", outage_start_timesteps),
    ("TimeStamp", TimeStamp),
    ("OutageLength_TimeSteps_Input", OutageLength_TimeSteps_Input),
    ("m_outagesimulator", m_outagesimulator),
    ("DataDictionaryForEachNode", DataDictionaryForEachNode),
    ("outage_simulator_results_for_plotting", outage_simulator_results_for_plotting),
    ("Compiled_results)
])
=#

using Plots, JuMP

function multinode_create_plots(data_dictionary_for_plots, filepath_for_saving_plots, time_steps_for_results_dashboard, data_eng)

    # Extract some information from the inputs dictionary
    Multinode_Inputs = data_dictionary_for_plots["Multinode_Inputs"]
    DataDictionaryForEachNode = data_dictionary_for_plots["DataDictionaryForEachNode"]
    TimeStamp = data_dictionary_for_plots["TimeStamp"]
    CompiledResults = data_dictionary_for_plots["CompiledResults"]

    phases_for_each_line =  REopt.create_dictionary_of_phases_for_each_line(data_eng)  # Initiate this dictionary with just the phases for each line; 
    phases_for_each_line_and_transformer_line, lines, transformer_busses = REopt.add_transformer_lines_to_the_dictionary(data_eng, collect(keys(data_eng["line"])), phases_for_each_line) # Then add the line IDs and phases for each transformer, representing the transformers as lines
    all_lines_including_transformers_as_lines =  collect(keys(phases_for_each_line_and_transformer_line))

    if length(filepath_for_saving_plots) > 75
        @warn "The file path entered into the multinode_create_plots function is long and the code may error when trying to save the plots"
    end

    # Generate warnings or errors for improper inputs into the multinode plotting function
    if Multinode_Inputs.number_of_plots_from_outage_simulator > Multinode_Inputs.number_of_outages_to_simulate
        @warn("In the Multinode_Inputs dictionary, the number_of_plots_from_outage_simulator is larger than the number_of_outages_to_simulate, so fewer plots than indicated by number_of_plots_from_outage_simulator will be generated.")
    end

    # If only using PMD (and not the simple powerflow model), then prevent trying to plot a REopt timestep that does not exist in the PMD model
    if !(Multinode_Inputs.apply_simple_powerflow_model_to_timesteps_that_do_not_use_PMD)
        #print("\n applying simple power flow: ")
        #print(Multinode_Inputs.apply_simple_powerflow_model_to_timesteps_that_do_not_use_PMD)
        for i in time_steps_for_results_dashboard
            if i ∉ Multinode_Inputs.PMD_time_steps
                throw(@error("Because the simple powerflow model is not being used, please make this adjustment to the model inputs: every time step for the results dashboard (time_steps_for_results_dashboard) must be in the PMD time steps (PMD_time_steps)."))
            end
        end
    end

    if maximum(time_steps_for_results_dashboard) > Int(8760*Multinode_Inputs.time_steps_per_hour)
        throw(@error("The entries in the time_steps_for_results_dashboard array should not exceed the maximum number of timesteps"))
    elseif minimum(time_steps_for_results_dashboard) < 1
        throw(@error("The entries in the time_steps_for_results_dashboard array should not by less than 1"))
    end

    if data_dictionary_for_plots["voltage_plot_time_step"] > length(Multinode_Inputs.PMD_time_steps)
        throw(@error("In the Multinode_Inputs dictionary, the voltage_plot_time_step should be less than or equal to the number of timesteps in PMD_time_steps"))
    end

    # Create a folder for the results
    folder = filepath_for_saving_plots*"/plots_"*TimeStamp
    mkdir(folder)


    # Plot outage simulator results if the outage simulator was run
    if Multinode_Inputs.run_outage_simulator
        mkdir(folder*"/Outage_Simulation_Plots")

        for y in collect(keys(data_dictionary_for_plots["outage_simulator_results_for_plotting"]))
            
            MapOutageSimulatorResultsPlots(Multinode_Inputs, 
                                        data_dictionary_for_plots["outage_survival_results"][y], 
                                        data_dictionary_for_plots["outage_start_timesteps_checked"][y], 
                                        data_dictionary_for_plots["TimeStamp"], 
                                        y,
                                        folder)
            
            values = collect(keys(data_dictionary_for_plots["outage_simulator_results_for_plotting"][y]))
            run_values = filter(x-> x isa Int, values)
            
            for z in run_values
                data = data_dictionary_for_plots["outage_simulator_results_for_plotting"][y][z]
                print("\n making plots for $(y),$(z)")
                m_outagesimulator = data["model"]
                NodeList = data["NodeList"]
                x = data["x"]
                i = data["i"]
                TotalTimeSteps = data["TotalTimeSteps"]
                OutageLength_TimeSteps_Input = y
                if termination_status(m_outagesimulator) == JuMP.OPTIMAL # double check that the outage simulator solved
                    CreatePlotsForOutageSimulatorModel(Multinode_Inputs, m_outagesimulator, DataDictionaryForEachNode, OutageLength_TimeSteps_Input, TimeStamp, TotalTimeSteps, NodeList, x, i, folder)
                end
            end
        end
    end

    # Create a voltage plot
    if Multinode_Inputs.number_of_phases == 1
        REoptPlots.Create_Voltage_Plot(CompiledResults, TimeStamp, data_dictionary_for_plots["voltage_plot_time_step"], folder)
    else
        @info "The creation of the voltage plots is currently only applicable for single phase systems"
    end

    # Plot the power flows on a map, if bus coordinates were provided
    if Multinode_Inputs.bus_coordinates != ""
        PMD_line_info = data_eng["line"]
        lines_in_PMD = collect(keys(data_eng["line"])) # Vector of line names based on data in PMD (which doesn't represent the transformers as lines)  

        REoptPlots.PlotPowerFlows(CompiledResults, TimeStamp, time_steps_for_results_dashboard, folder, all_lines_including_transformers_as_lines, lines_in_PMD, PMD_line_info)

        REoptPlots.Aggregated_PowerFlows_Plot(CompiledResults, TimeStamp, Multinode_Inputs, data_dictionary_for_plots["REoptInputs_Combined"], data_dictionary_for_plots["model"], folder)

        REoptPlots.CreateResultsMap(CompiledResults, Multinode_Inputs, TimeStamp, folder, all_lines_including_transformers_as_lines, lines_in_PMD, PMD_line_info)
    end
    
end


function CreateResultsMap(results, Multinode_Inputs, TimeStamp, folder, all_lines_including_transformers_as_lines, lines_in_PMD, PMD_line_info)

    bus_key_values, line_key_values, bus_cords, line_cords, busses = REopt.CollectMapInformation(results, Multinode_Inputs, all_lines_including_transformers_as_lines, lines_in_PMD, PMD_line_info) 

    if Multinode_Inputs.display_information_during_modeling_run
        print("\n For plotting the Results and Layout map: \n")
        print("\n The bus_key_values are: $(bus_key_values) \n")
        print("\n The bus_cords are: $(bus_cords) \n") 
        print("\n The line_key_values are: $(line_key_values) \n")
        print("\n The line_cords are: $(line_cords) \n")
        print("\n all_lines_including_transformers_as_lines are: $(all_lines_including_transformers_as_lines)")
    end 

    results_by_node = REopt.CollectResultsByNode(results, busses)

    traces = PlotlyJS.GenericTrace[] # initiate the vector as a vector of PlotlyJS traces

    # Add traces for the nodes
    for i in 1:length(bus_key_values)
        trace_bus = PlotlyJS.scattergeo(;locationmode = "USA-states",
                        lat = [bus_cords[bus_key_values[i]][1]],
                        lon = [bus_cords[bus_key_values[i]][2]],
                        marker_size = 8,
                        marker_color = "blue",
                        mode = "markers+text",
                        text = bus_key_values[i]*results_by_node[bus_key_values[i]], # Show the technology sizing next to each node
                        textposition = "right"
                        )
        push!(traces, trace_bus)
    end

    # Add traces for the lines
    for i in 1:length(line_key_values)
        trace_line     = PlotlyJS.scattergeo(;locationmode = "USA-states",
                    lat = [line_cords[line_key_values[i]][1][1], line_cords[line_key_values[i]][2][1]],
                    lon = [line_cords[line_key_values[i]][1][2], line_cords[line_key_values[i]][2][2]],
                    mode = "lines",
                    line_color = "black",
                    line_width = 2) 
        push!(traces, trace_line)
    end
    geo = PlotlyJS.attr(scope = "usa",
                projection_type = "albers usa",
                showland = true,
                landcolor = "rgb(217,217,217)",
                subunitwidth =1,
                countrywidth=1,
                fitbounds = "locations",
                subunitcolor = "rgb(255,255,255)",
                countrycolor = "rgb(255,255,255)")
    layout = PlotlyJS.Layout(; title="Multinode Results and Layout", geo=geo,  showlegend = false)
    
    p = PlotlyJS.plot(traces,layout)
    PlotlyJS.savefig(p, folder*"/Results_and_Layout.html")
    
end


function Create_Voltage_Plot(results, TimeStamp, voltage_plot_time_step, folder; file_suffix="")
    Multinode_Inputs = results["Multinode_Inputs"]
    # Generate list of lengths from the node to the substation
    DistancesToSourcebus, lengths_dict, paths_dict, paths, neighbors = REopt.DetermineDistanceFromSourcebus(Multinode_Inputs, results["PMD_data_eng"])

    # Determine the per unit voltage at each node
    timestep = voltage_plot_time_step
    
    per_unit_voltage = Dict([])
    for bus in keys(DistancesToSourcebus)
        if "w" in keys(results["PMD_results"]["nw"][string(timestep)]["bus"][bus])
            per_unit_voltage[bus] = sqrt(results["PMD_results"]["nw"][string(timestep)]["bus"][bus]["w"][1])
        elseif "Wr" in keys(results["PMD_results"]["nw"][string(timestep)]["bus"][bus])
            per_unit_voltage[bus] = sqrt(results["PMD_results"]["nw"][string(timestep)]["bus"][bus]["Wr"][1][1]) # TODO: figure out what "Wi" is in the results when using the SOCNLPUBFPowerModel formulation
        else
            throw(@error("Bus voltage results data is not available"))
        end
     end

    # Interactive plot using PlotlyJS
    traces = PlotlyJS.GenericTrace[]
    layout = PlotlyJS.Layout(title_text = "Voltage Stability, PMD Timestep $(timestep)", xaxis_title_text = "Distance from Substation", yaxis_title_text = "Per Unit Voltage")
    
    for line in keys(results["PMD_data_eng"]["line"])
        bus1 = results["PMD_data_eng"]["line"][line]["f_bus"]
        bus2 = results["PMD_data_eng"]["line"][line]["t_bus"]
        push!(traces, PlotlyJS.scatter(name = "Line $(line)", showlegend = false, fill = "none", line = PlotlyJS.attr(width = 1, color="black"),
                x = [DistancesToSourcebus[string(bus1)], DistancesToSourcebus[string(bus2)]],
                y = [per_unit_voltage[string(bus1)], per_unit_voltage[string(bus2)]]
            ))
    end

    for bus in keys(DistancesToSourcebus)
        voltage = round(per_unit_voltage[bus], digits = 6)
        push!(traces, PlotlyJS.scatter(name = "Node $(bus)", showlegend = false, text ="Node $(bus), p.u. voltage $(voltage)", hoverinfo = "text", fill = "none", line = PlotlyJS.attr(width = 3, color="black"),
                x = [DistancesToSourcebus[bus]],
                y = [per_unit_voltage[bus]]
            ))
    end       

    p = PlotlyJS.plot(traces, layout)
    PlotlyJS.savefig(p, folder*"/VoltagePlot_InteractivePlot"*file_suffix*".html")
    
    #display(p)
    
end


function Aggregated_PowerFlows_Plot(results, TimeStamp, Multinode_Inputs, REoptInputs_Combined, model, folder)
    # Function to create additional plots using PlotlyJS
    
    OutageStartTimeStep = Multinode_Inputs.single_outage_start_time_step
    OutageStopTimeStep = Multinode_Inputs.single_outage_end_time_step

    NodeList = []
    for i in Multinode_Inputs.REopt_inputs_list
        push!(NodeList, i["Site"]["node"])
    end

    TotalLoad_series = zeros(Multinode_Inputs.time_steps_per_hour * 8760) # initiate the total load as 0
    for n in NodeList
        TotalLoad_series = TotalLoad_series + results["REopt_results"][n]["ElectricLoad"]["load_series_kw"] 
    end

    # determine all of the nodes with PV and determine total PV output across the entire network
    NodesWithPV = []
    for i in keys(results["REopt_results"])
        if "PV" in keys(results["REopt_results"][i])
            push!(NodesWithPV, i)
        end
    end
    
    # determine all of the nodes with Battery
    NodesWithBattery = []
    for i in keys(results["REopt_results"])
        if "ElectricStorage" in keys(results["REopt_results"][i])
            push!(NodesWithBattery, i)
        end
    end

    if Multinode_Inputs.display_information_during_modeling_run
        print("\n The nodes with PV are: ")
        print(NodesWithPV)
    end

    PVOutput = zeros(Multinode_Inputs.time_steps_per_hour * 8760)
    for NodeNumberTemp in NodesWithPV
        PVOutput = PVOutput + results["REopt_results"][NodeNumberTemp]["PV"]["electric_to_load_series_kw"] + results["REopt_results"][NodeNumberTemp]["PV"]["electric_to_grid_series_kw"]
        if NodeNumberTemp in NodesWithBattery
            if results["REopt_results"][NodeNumberTemp]["ElectricStorage"]["size_kw"] > 0
                PVOutput = PVOutput + results["REopt_results"][NodeNumberTemp]["PV"]["electric_to_storage_series_kw"]
            end
        end
    end

    BatteryOutput = zeros(Multinode_Inputs.time_steps_per_hour * 8760)
    BatteryCharging = zeros(Multinode_Inputs.time_steps_per_hour * 8760)
    for NodeNumberTemp in NodesWithBattery
        if results["REopt_results"][NodeNumberTemp]["ElectricStorage"]["size_kw"] > 0  # include this if statement to prevent trying to add in empty electric storage time series vectors
            BatteryOutput = BatteryOutput + results["REopt_results"][NodeNumberTemp]["ElectricStorage"]["storage_to_load_series_kw"] + results["REopt_results"][NodeNumberTemp]["ElectricStorage"]["storage_to_grid_series_kw"] 
            
            BatteryCharging = BatteryCharging + results["REopt_results"][NodeNumberTemp]["ElectricUtility"]["electric_to_storage_series_kw"]
            if "PV" in keys(results["REopt_results"][NodeNumberTemp])
                BatteryCharging = BatteryCharging + results["REopt_results"][NodeNumberTemp]["PV"]["electric_to_storage_series_kw"]
            end
            if "Generator" in keys(results["REopt_results"][NodeNumberTemp])
                BatteryCharging = BatteryCharging + results["REopt_results"][NodeNumberTemp]["Generator"]["electric_to_storage_series_kw"].data
            end
        end
    end

    # determine all of the nodes with generator
    NodesWithGenerator = []
    for i in keys(results["REopt_results"])
        if "Generator" in keys(results["REopt_results"][i])
            push!(NodesWithGenerator, i)
        end
    end
    GeneratorOutput = zeros(Multinode_Inputs.time_steps_per_hour * 8760)
    for NodeNumberTemp in NodesWithGenerator
        GeneratorOutput = GeneratorOutput + results["REopt_results"][NodeNumberTemp]["Generator"]["electric_to_load_series_kw"].data + results["REopt_results"][NodeNumberTemp]["Generator"]["electric_to_grid_series_kw"].data  # + results["REopt_results"][NodeNumberTemp]["Generator"]["electric_to_storage_series_kw"].data 
    end
    
    # Save the REopt Inputs for the site not to a variable
    FacilityMeterNode_REoptInputs = ""
    for p in REoptInputs_Combined
        if string(p.s.site.node) == p.s.settings.facilitymeter_node
            FacilityMeterNode_REoptInputs = p        
        end
    end
    
    # Save power input from the grid to a variable for plotting
    PowerFromGrid = zeros(Multinode_Inputs.time_steps_per_hour * 8760)
    if Multinode_Inputs.model_type == "PowerModelsDistribution"    
        PowerFromGrid = value.(model[Symbol("dvSubstationPowerFlow")]).data  
    end 
       
    #Plot the network-wide power use in a static plot
    days = collect(1:(Multinode_Inputs.time_steps_per_hour * 8760))/(Multinode_Inputs.time_steps_per_hour * 24)
    Plots.plot(days, TotalLoad_series, label="Total Load")
    Plots.plot!(days, PVOutput, label="Combined PV Output")
    Plots.plot!(days, BatteryOutput, label = "Combined Battery Output")
    Plots.plot!(days, BatteryCharging, label = "Combined Battery Charging")
    Plots.plot!(days, GeneratorOutput, label = "Combined Generator Output")
    Plots.plot!(days, PowerFromGrid, label = "Grid Power")
    if Multinode_Inputs.model_outages_with_outages_vector
        if Multinode_Inputs.outages_vector != []
            # TODO: model the multiple outages in the static plot
        end
    elseif (OutageStopTimeStep - OutageStartTimeStep) > 0
        OutageStart_Line = OutageStartTimeStep/24
        OutageStop_Line = OutageStopTimeStep/24
        Plots.plot!([OutageStart_Line, OutageStart_Line],[0,maximum(TotalLoad_series)], label= "Outage Start")
        Plots.plot!([OutageStop_Line, OutageStop_Line],[0,maximum(TotalLoad_series)], label= "Outage End")
        Plots.xlims!(OutageStartTimeStep-12, OutageStopTimeStep+12)
    else
        Plots.xlims!(0,7*Multinode_Inputs.time_steps_per_hour) # Show the first week of results
    end

    Plots.title!("System Wide Power Demand and Generation")
    
    # Interactive plot using PlotlyJS
    traces = PlotlyJS.GenericTrace[]
    layout = PlotlyJS.Layout(title_text = "System Wide Power Demand and Generation", xaxis_title_text = "Day", yaxis_title_text = "Power (kW)")
    
    if Multinode_Inputs.model_type == "PowerModelsDistribution"
        
        max = 1.1 * maximum([maximum(TotalLoad_series), maximum(PVOutput), maximum(BatteryOutput), maximum(GeneratorOutput), maximum(PowerFromGrid)])
        min = 1.1 * minimum([minimum(TotalLoad_series), minimum(PVOutput), minimum(BatteryOutput), minimum(GeneratorOutput), minimum(PowerFromGrid)])

        start_values = []
        end_values = []
    
        PMD_TimeSteps_inREoptTime =  Multinode_Inputs.PMD_time_steps

        for i in collect(1:length(PMD_TimeSteps_inREoptTime))
            if i == 1
                push!(start_values, PMD_TimeSteps_inREoptTime[i])
            elseif i == length(PMD_TimeSteps_inREoptTime)
                push!(end_values, PMD_TimeSteps_inREoptTime[i])
            elseif PMD_TimeSteps_inREoptTime[i+1] - PMD_TimeSteps_inREoptTime[i] > 1
                push!(start_values, PMD_TimeSteps_inREoptTime[i+1])
                push!(end_values, PMD_TimeSteps_inREoptTime[i])
            else
                # Do nothing
            end
        end

        for i in collect(1:length(start_values))
            start_temp = start_values[i] / (24* Multinode_Inputs.time_steps_per_hour)
            end_temp = end_values[i] / (24* Multinode_Inputs.time_steps_per_hour)
            
            if i == 1
                legend = true
            else
                legend = false
            end
            push!(traces, PlotlyJS.scatter(name = "PMD Timesteps", showlegend = legend, fill = "toself", 
                x = [start_temp,start_temp,end_temp,end_temp,start_temp],
                y = [min,max,max,min,min],
                mode = "lines",
                line = PlotlyJS.attr(width=0),
                fillcolor = "gray",
                opacity = 0.35
            ))
        end  
    end

    push!(traces, PlotlyJS.scatter(name = "Total load", showlegend = true, fill = "none", line = PlotlyJS.attr(width = 3, color="black", dash="dot"),
        x = days,
        y = TotalLoad_series
    ))
    push!(traces, PlotlyJS.scatter(name = "Combined PV Output", showlegend = true, fill = "none", line = PlotlyJS.attr(width = 3, color="green"),
        x = days,
        y = PVOutput
    ))
    push!(traces, PlotlyJS.scatter(name = "Combined Battery Output", showlegend = true, fill = "none", line = PlotlyJS.attr(width = 3, color="blue"),
        x = days,
        y = BatteryOutput
    ))
    push!(traces, PlotlyJS.scatter(name = "Combined Battery Charging", showlegend = true, fill = "none", line = PlotlyJS.attr(width = 3, color="rgb(37, 213, 255)"), # light blue
        x = days,
        y = -BatteryCharging
    ))
    push!(traces, PlotlyJS.scatter(name = "Combined Generator Output", showlegend = true, fill = "none", line = PlotlyJS.attr(width = 3, color="gray"),
        x = days,
        y = GeneratorOutput
    ))    
    push!(traces, PlotlyJS.scatter(name = "Power from Substation", showlegend = true, fill = "none", line = PlotlyJS.attr(width = 3, color="orange"),
        x = days,
        y = PowerFromGrid
    ))  
    
    if Multinode_Inputs.model_outages_with_outages_vector
        if Multinode_Inputs.outages_vector != []
            
            outage_starts, outage_ends = DetermineOutageStartsAndEnds(Multinode_Inputs, Multinode_Inputs.outages_vector)
            
            for i in outage_starts
                if i == outage_starts[1]
                    showlegend = true
                else
                    showlegend = false
                end
                push!(traces, PlotlyJS.scatter(name = "Outage Start", showlegend = showlegend, fill = "none", line = PlotlyJS.attr(width = 3, color="red"),
                    x = [i, i],
                    y = [0,maximum(TotalLoad_series)]
                ))
            end 

            for i in outage_ends
                if i == outage_ends[1]
                    showlegend = true
                else
                    showlegend = false
                end
                push!(traces, PlotlyJS.scatter(name = "Outage End", showlegend = showlegend, fill = "none", line = PlotlyJS.attr(width = 3, color="red", dash="dot"),
                    x = [i, i],
                    y = [0,maximum(TotalLoad_series)]
                ))
            end 

        end
    elseif (OutageStopTimeStep - OutageStartTimeStep) > 0
        OutageStart_Line = OutageStartTimeStep/(24 * Multinode_Inputs.time_steps_per_hour)
        OutageStop_Line = OutageStopTimeStep/(24 * Multinode_Inputs.time_steps_per_hour)
        push!(traces, PlotlyJS.scatter(name = "Outage Start", showlegend = true, fill = "none", line = PlotlyJS.attr(width = 3, color="red", dash="dot"),
            x = [OutageStart_Line, OutageStart_Line],
            y = [0,maximum(TotalLoad_series)]
        ))  
        push!(traces, PlotlyJS.scatter(name = "Outage End", showlegend = true, fill = "none", line = PlotlyJS.attr(width = 3, color="red", dash="dot"),
            x = [OutageStop_Line, OutageStop_Line],
            y = [0,maximum(TotalLoad_series)]
        ))  
    end

    p = PlotlyJS.plot(traces, layout)
    PlotlyJS.savefig(p, folder*"/CombinedResults_PowerOutput_InteractivePlot.html")
    
    #display(p)
    
end
 

function PlotPowerFlows(results, TimeStamp, REopt_timesteps_for_dashboard_InREoptTimes, folder, all_lines_including_transformers_as_lines, lines_in_PMD, PMD_line_info; file_suffix="")
    # This function plots the power flows through the network

    Multinode_Inputs = results["Multinode_Inputs"]
    bus_key_values, line_key_values, bus_cords, line_cords, busses, substation_cords = REopt.CollectMapInformation(results, Multinode_Inputs, all_lines_including_transformers_as_lines, lines_in_PMD, PMD_line_info) 
    results_by_node = REopt.CollectResultsByNode(results, busses)

    Multinode_Inputs.display_information_during_modeling_run ? print("\n The substation coordinates are: $(substation_cords)") : nothing

    # Determine the timesteps to plot based on the timesteps the user requested to plot in the dashboard
    maximum_timestep = maximum(REopt_timesteps_for_dashboard_InREoptTimes)
    minimum_timestep = minimum(REopt_timesteps_for_dashboard_InREoptTimes)
    PMDTimeSteps_InREoptTimes = Multinode_Inputs.PMD_time_steps
    timesteps = REopt_timesteps_for_dashboard_InREoptTimes # PMDTimeSteps_for_dashboard_InPMDTimes    
    
    model_total_timesteps = Int(8760*Multinode_Inputs.time_steps_per_hour) 

    #=
    PMDTimeSteps_for_dashboard_InPMDTimes = []
    PMD_dashboard_InPMDTimes_toREoptTimes = Dict([])
    for timestep in REopt_timesteps_for_dashboard_InREoptTimes
        PMD_time_step_IndecesForDashboard = findall(x -> x==timestep, PMDTimeSteps_InREoptTimes)[1] #use the [1] to convert the 1-element vector into an integer
        push!(PMDTimeSteps_for_dashboard_InPMDTimes, PMD_time_step_IndecesForDashboard)
        PMD_dashboard_InPMDTimes_toREoptTimes[PMD_time_step_IndecesForDashboard] = timestep
    end
    =#

    if Multinode_Inputs.model_outages_with_outages_vector 
        PowerOutageIndicator = Array{String}(undef, model_total_timesteps)
        PowerOutageIndicator[:] .= "Not defined"
        for timestep in collect(1:model_total_timesteps) # REopt_timesteps_for_dashboard_InREoptTimes #PMDTimeSteps_for_dashboard_InPMDTimes
            if timestep in Multinode_Inputs.outages_vector
                PowerOutageIndicator[timestep] = " Grid outage"
            else
                PowerOutageIndicator[timestep] = ""
            end
        end
    elseif (Multinode_Inputs.single_outage_end_time_step - Multinode_Inputs.single_outage_start_time_step) > 0
        PowerOutageIndicator = Array{String}(undef, model_total_timesteps)
        PowerOutageIndicator[:] .= "Not defined"
        for timestep in collect(1:model_total_timesteps) # REopt_timesteps_for_dashboard_InREoptTimes # PMDTimeSteps_for_dashboard_InPMDTimes
            if (timestep >= Multinode_Inputs.single_outage_start_time_step) && (timestep <= Multinode_Inputs.single_outage_end_time_step)
                PowerOutageIndicator[timestep] = " Grid outage"
            else
                PowerOutageIndicator[timestep] = ""
            end
        end
    else
        PowerOutageIndicator = repeat([""], model_total_timesteps)
    end
    
    PowerFlowModelIndicator = Array{String}(undef, model_total_timesteps)
    PowerFlowModelIndicator[:] .= "Not defined"
    if Multinode_Inputs.apply_simple_powerflow_model_to_timesteps_that_do_not_use_PMD
        for timestep in collect(1:model_total_timesteps) # timesteps
            if timestep in PMDTimeSteps_InREoptTimes
                PowerFlowModelIndicator[timestep] = "Model: PMD"
            else
                PowerFlowModelIndicator[timestep] = "Model: Simple Powerflow"
            end
        end
    else
        PowerFlowModelIndicator[:] .= "Model: PMD"
    end

    if Multinode_Inputs.display_information_during_modeling_run
        print("\n Timesteps for dashboard (in REopt times) are: ")
        print(timesteps)
    end

    # *******
    # The method in these asterisks came from ChatGPT
    color1 = [30,62,250] # blue
    color2 = [0,255,255] # cyan
    color3 = [255,255,0] # yellow
    color4 = [238,155,0] # orange
    color5 = [215,20,20] # red
    increments = 20 # steps must be a even number
    color1_to_color2 = [color1 .+ (color2 .- color1) * i / ((increments/4)-1) for i in 0:(Int(increments/4)-1) ]
    color2_to_color3 = [color2 .+ (color3 .- color2) * i / ((increments/4)-1) for i in 0:(Int(increments/4)-1) ]
    color3_to_color4 = [color3 .+ (color4 .- color3) * i / ((increments/4)-1) for i in 0:(Int(increments/4)-1) ]
    color4_to_color5 = [color4 .+ (color5 .- color4) * i / ((increments/4)-1) for i in 0:(Int(increments/4)-1) ]
    
    color_numbers = vcat(color1_to_color2, color2_to_color3, color3_to_color4, color4_to_color5)
    
    Colors = [string("rgb(",Int(round(c[1])),",",Int(round(c[2])),",",Int(round(c[3])),")") for c in color_numbers]
    #*******
    
    deleteat!(Colors, increments) # with 20 increments, there should only be 19 color bins

    # Determine the maximum power in the data that is being plotted:
    powerflow = results["Dictionary_LineFlow_Power_Series"]
    max_power = 0
    power = 0
    for key in collect(keys(results["Dictionary_LineFlow_Power_Series"]))
        for i in timesteps
            p = results["Dictionary_LineFlow_Power_Series"][key]["ActiveLineFlow"][i]
            if typeof(p) != String
                power = abs(p)
                if power > max_power
                    max_power = power
                end
            end
        end
    end

    if max_power > 50
        Color_bins = round.(collect(range(0,(ceil(max_power/10)*10),increments)))
    elseif max_power < 10
        increments = Int(increments/2)
        Color_bins = round.(collect(range(0,max_power,increments)), digits=2)
    else
        increments = Int(increments/2)
        Color_bins = round.(collect(range(0,ceil(max_power),increments)), digits=2)
    end
    
    line_colors = Dict{Any, Any}()
    for line in line_key_values
        if !startswith(line, "xfmr_line")
            line_colors[line] = Vector{String}(undef, maximum(model_total_timesteps))
            line_colors[line][:] .= "rgb(1,1,1)" # default rgb(1,1,1), which indicates that data is not shown properly for that timestep
            for i in collect(1:model_total_timesteps) 
                for j in 1:(length(Color_bins)-1)
                    if typeof(powerflow[line]["ActiveLineFlow"][i]) != String
                        if abs(powerflow[line]["ActiveLineFlow"][i]) <= 0.001
                            line_colors[line][i] = "rgb(127, 137, 145)" # Grey line indicates no power flow
                        elseif (abs(powerflow[line]["ActiveLineFlow"][i]) >= Color_bins[j]) && (abs(powerflow[line]["ActiveLineFlow"][i]) <= Color_bins[j+1])
                            line_colors[line][i] = Colors[j]
                        end
                    end
                end
            end
        else
            line_colors[line] = Vector{String}(undef, maximum(model_total_timesteps))
            line_colors[line][:] .= "rgb(85,85,85)" # default rgb(1,1,1), which indicates that there is a transformer there
        end
    end
    
    x_bus_values = zeros(length(keys(bus_cords)))
    y_bus_values = zeros(length(keys(bus_cords)))

    for i in collect(1:length(keys(bus_cords)))
        x_bus_values[i] = bus_cords[collect(keys(bus_cords))[i]][2]
        y_bus_values[i] = bus_cords[collect(keys(bus_cords))[i]][1]
    end

    minx = minimum(x_bus_values)
    maxx = maximum(x_bus_values)
    miny = minimum(y_bus_values)
    maxy = maximum(y_bus_values)
    y0 = zeros(increments)
    y1 = zeros(increments)
    stepsize = (maxy - miny)/increments
    x_spacing = 0.05*(maxx - minx)
    legend_box_width = 0.02*(maxx - minx)
    x0 = maxx + x_spacing
    x1 = maxx + x_spacing + legend_box_width
    scaleratio_input = 0.85 # TODO: determine if this scale ratio should be different for different latitudes

    for i in collect(1:increments)
        y0[i] = miny + ((i-1)*stepsize)
        y1[i] = miny + (i * stepsize)
    end

    start_day = minimum_timestep/(24*Multinode_Inputs.time_steps_per_hour)
    end_day = maximum_timestep/(24*Multinode_Inputs.time_steps_per_hour)
    Symbol_data_inputs = SymbolData(results, line_cords, REopt_timesteps_for_dashboard_InREoptTimes, minx, maxx, scaleratio_input)

    start_datetime = Dates.format(DateTime(2021, 1, 1) + Day(floor(start_day)) + Second(round(60*60*24*(start_day - floor(start_day)))), "U d at HH:MM") # This line of code is based off of code suggested by generative AI
    end_datetime = Dates.format(DateTime(2021, 1, 1) + Day(floor(end_day)) + Second(round(60*60*24*(end_day - floor(end_day)))), "U d at HH:MM") # This line of code is based off of code suggested by generative AI

    if Multinode_Inputs.number_of_phases == 1
        phase_labels = []
    elseif (Multinode_Inputs.number_of_phases == 2) || (Multinode_Inputs.number_of_phases == 3)
        phases_for_each_line = REopt.create_dictionary_of_phases_for_each_line(results["PMD_data_eng"])
        phases_for_each_line_and_transformer_line, lines, transformer_busses = REopt.add_transformer_lines_to_the_dictionary(results["PMD_data_eng"], collect(keys(results["PMD_data_eng"]["line"])), phases_for_each_line) # Then add the line IDs and phases for each transformer, representing the transformers as lines
        phase_information = phases_for_each_line_and_transformer_line

        print("\n Phase information is: $(phase_information)")
        phase_labels = [PlotlyJS.attr(xref='x', yref='y', xanchor="left", yanchor="bottom",
                                          x= Symbol_data_inputs[line_key_values[k]][1][1], 
                                          y= Symbol_data_inputs[line_key_values[k]][1][2],
                                          text = "Ø"*string(phase_information[line_key_values[k]]),
                                          showarrow=false
                                ) for k in 1:length(line_cords)]
    else
        throw(@error("The number of phases defined in the multi-node inputs dictionary is invalid."))
    end
    
    frames = PlotlyJS.PlotlyFrame[ PlotlyJS.frame(             
            data = [PlotlyJS.scatter(x=[line_cords[line_key_values[i]][1][2], line_cords[line_key_values[i]][2][2]], y=[line_cords[line_key_values[i]][1][1], line_cords[line_key_values[i]][2][1]], mode="lines+markers",marker=PlotlyJS.attr(color="black"), line=PlotlyJS.attr(width=3, color = line_colors[line_key_values[i]][j])) for i in collect(1:length(line_cords))], 
            name = "time=$(j)",
            layout=PlotlyJS.attr(title_text="Power Flow Time Series Animation, from  $(start_datetime)  to  $(end_datetime)", 
                                 xaxis_title_text = "",
                                 yaxis_title_text = "",
                                 annotations = vcat([PlotlyJS.attr(x=x1,y=y0[i],text=string(Color_bins[i])*" kW", xanchor="left", yanchor="center", showarrow=false) for i in collect(1:increments)],
                                                    [PlotlyJS.attr(x=x1,y=y0[1] - stepsize,text="0 kW", xanchor="left", yanchor="center", showarrow=false)], 
                                                    [PlotlyJS.attr(x=x1,y=y1[increments],text="Power (kW)", xanchor="center", yanchor="bottom", showarrow=false)],
                                                    [PlotlyJS.attr(x=substation_cords[2], y=substation_cords[1], text=PowerOutageIndicator[j], font = PlotlyJS.attr(color="red", size = 16), xanchor="left", yanchor="bottom", showarrow=false)],
                                                    [PlotlyJS.attr(x=x1, y=y1[increments]+stepsize+(stepsize/2), text=PowerFlowModelIndicator[j], font = PlotlyJS.attr(color="black", size = 16), xanchor="right", yanchor="bottom", showarrow=false)],
                                                    phase_labels,
                                                    [PlotlyJS.attr(x=bus_cords[bus_key_values[j]][2], y=bus_cords[bus_key_values[j]][1], text=bus_key_values[j]*results_by_node[bus_key_values[j]], xanchor="right", yanchor="bottom", showarrow=false) for j in 1:length(bus_key_values) ]),
             
                                 shapes = vcat([PlotlyJS.line(xref='x', yref='y', 
                                                         x0= Symbol_data_inputs[line_key_values[k]][1][1], 
                                                         y0= Symbol_data_inputs[line_key_values[k]][1][2], 
                                                         x1= Symbol_data_inputs[line_key_values[k]][3][j], 
                                                         y1= Symbol_data_inputs[line_key_values[k]][4][j], 
                                                         line = PlotlyJS.attr(color=line_colors[line_key_values[k]][j]), 
                                                         ) for k in 1:length(line_cords)],
                                                [PlotlyJS.line(xref='x', yref='y', 
                                                         x0= Symbol_data_inputs[line_key_values[k]][1][1], 
                                                         y0= Symbol_data_inputs[line_key_values[k]][1][2], 
                                                         x1= Symbol_data_inputs[line_key_values[k]][5][j], 
                                                         y1= Symbol_data_inputs[line_key_values[k]][6][j], 
                                                         line = PlotlyJS.attr(color=line_colors[line_key_values[k]][j]), 
                                                         ) for k in 1:length(line_cords)],
                                               [PlotlyJS.rect(x0=x0, y0= y0[i], x1=x1, y1=y1[i], fillcolor=Colors[i], line=PlotlyJS.attr(width=0), xref='x',yref='y') for i in collect(1:(increments-1))],
                                               [PlotlyJS.rect(x0=x0, y0= y0[1] - stepsize - (stepsize/2), x1=x1, y1=y1[1] - stepsize - (stepsize/2), fillcolor="rgb(127, 137, 145)", line=PlotlyJS.attr(width=0), xref='x',yref='y')]
                                               )
                                )) for j in timesteps]
    
    steps_days = [Dates.format(DateTime(2021, 1, 1) + Day(floor(day)) + Second(round(60*60*24*(day - floor(day)))), "U d at HH:MM") for day in (collect(1:model_total_timesteps)/(24*Multinode_Inputs.time_steps_per_hour))]# This line of code is based off of code suggested by generative AI
    
    steps = [PlotlyJS.attr(method = "animate",
            args = [["time=$(i)"], PlotlyJS.attr(frame=PlotlyJS.attr(duration=500, redraw=true), mode="immediate", transition=PlotlyJS.attr(duration=0))],
            #label = "$(round(i/(24*Multinode_Inputs.time_steps_per_hour), digits=2))") for i in timesteps]
            label = steps_days[i]*" (ts=$(i))") for i in timesteps]
    layout = PlotlyJS.Layout(
        showlegend=false,
        xaxis = PlotlyJS.attr(showticklabels=false, scaleanchor='y', scaleratio = scaleratio_input),
        yaxis = PlotlyJS.attr(showticklabels=false, scaleanchor='x'),
        #annotations = vcat([PlotlyJS.attr(x=x1,y=y0[i],text=Color_bins[i], xanchor="left", yanchor="center", showarrow=false) for i in collect(1:increments)], 
        #                   [PlotlyJS.attr(x=x1,y=y1[increments],text="Power (kW)", xanchor="center", yanchor="bottom", showarrow=false)],
        #                   [PlotlyJS.attr(x=bus_cords[bus_key_values[j]][2], y=bus_cords[bus_key_values[j]][1], text=bus_key_values[j]*results_by_node[bus_key_values[j]], xanchor="left", yanchor="bottom", showarrow=false) for j in 1:length(bus_key_values) ]),
                          
                        
        sliders=[PlotlyJS.attr(yanchor="top", 
                    xanchor="left",
                    currentvalue=PlotlyJS.attr(prefix="Day: ", visible=true, font_size=12),
                    steps=steps,
                    active=0,
                    minorticklen=0
                    )],
        updatemenus = [PlotlyJS.attr(
            type="buttons",
            showactive=false,
            buttons=[
                PlotlyJS.attr(
                    label="Animate", method="animate",
                    args=[nothing,PlotlyJS.attr(transition=PlotlyJS.attr(duration=0),fromcurrent=true, visible=true, frame=PlotlyJS.attr(duration=500, redraw=true), mode="immediate")]),
                PlotlyJS.attr(
                    label="Pause", method="animate",
                    args=[[nothing],PlotlyJS.attr(transition=PlotlyJS.attr(duration=0), mode="immediate")])
        ])])
    
    data = [PlotlyJS.scatter(x=[line_cords[line_key_values[i]][1][2], line_cords[line_key_values[i]][2][2]], y=[line_cords[line_key_values[i]][1][1], line_cords[line_key_values[i]][2][1]], line=PlotlyJS.attr(width=3, color = line_colors[line_key_values[i]][timesteps[1]])) for i in 1:length(line_cords)]
            
    p = PlotlyJS.Plot(data, layout, frames)

    PlotlyJS.savefig(p, folder*"/PowerFlowAnimation"*file_suffix*".html")
    
    #display(p) # do not display because this plot does not work in VScode
    return frames, layout, steps, line_cords, bus_cords, data,  bus_key_values, line_key_values, line_colors, timesteps, powerflow, Symbol_data_inputs
end


function SymbolData(results, line_cords, timesteps_to_model, minx, maxx, scaleratio_input)
    # Function to generate information for mapping a power flow direction symbol in the power flow chart
    SymbolDictionary = Dict()
    powerflow = results["Dictionary_LineFlow_Power_Series"]
    
    for i in collect(keys(line_cords))
        if !(startswith(i, "xfmr_line"))
            midpoint = [0,0]
            x_average = 0.5 * (line_cords[i][1][2] + line_cords[i][2][2])
            y_average = 0.5 * (line_cords[i][1][1] + line_cords[i][2][1])
            midpoint = [x_average, y_average]
            
            x_change = line_cords[i][2][2] - line_cords[i][1][2]
            y_change = line_cords[i][2][1] - line_cords[i][1][1]
            if x_change != 0
                slope_radians = atan(y_change, x_change)
            elseif y_change > 0
                slope_radians = 3.14159 / 2
            elseif y_change < 0
                slope_radians = -3.14159 / 2
            end
            slope_degrees = slope_radians * (180 / 3.14159)
            SymbolDictionary[i] = [midpoint, slope_degrees, [], [], [], []] # initiate the arrays for the end points of the arrows
            arrow_angle_radians = pi / 4 
            arrow_length = 0.01 * (maxx - minx) # define the arrow length as a fraction of the plot size
            x2 = zeros(maximum(timesteps_to_model))
            y2 = zeros(maximum(timesteps_to_model))
            x3 = zeros(maximum(timesteps_to_model))
            y3 = zeros(maximum(timesteps_to_model))

            for j in timesteps_to_model
                active_power = powerflow[i]["ActiveLineFlow"][j]

                if active_power < -0.001
                    x2[j] = midpoint[1] + (arrow_length * cos(slope_radians + arrow_angle_radians))
                    y2[j] = midpoint[2] + (arrow_length * sin(slope_radians + arrow_angle_radians) * scaleratio_input)

                    x3[j] = midpoint[1] + (arrow_length * cos(slope_radians - arrow_angle_radians))
                    y3[j] = midpoint[2] + (arrow_length * sin(slope_radians - arrow_angle_radians) * scaleratio_input)
                
                elseif active_power > 0.001
                    x2[j] = midpoint[1] - (arrow_length * cos(slope_radians + arrow_angle_radians))
                    y2[j] = midpoint[2] - (arrow_length * sin(slope_radians + arrow_angle_radians) * scaleratio_input)

                    x3[j] = midpoint[1] - (arrow_length * cos(slope_radians - arrow_angle_radians))
                    y3[j] = midpoint[2] - (arrow_length * sin(slope_radians - arrow_angle_radians) * scaleratio_input)
                
                else
                    # If there is no power flow in the line, draw the angled line to start and stop at the midpoint (so no arrow will be shown)
                    x2[j] = midpoint[1]
                    y2[j] = midpoint[2]
                    x3[j] = midpoint[1]
                    y3[j] = midpoint[2]
                end
            end

            SymbolDictionary[i][3] = x2
            SymbolDictionary[i][4] = y2
            SymbolDictionary[i][5] = x3
            SymbolDictionary[i][6] = y3
        else
            midpoint = [0,0]
            x_average = 0.5 * (line_cords[i][1][2] + line_cords[i][2][2])
            y_average = 0.5 * (line_cords[i][1][1] + line_cords[i][2][1])
            midpoint = [x_average, y_average]
            slope_degrees = 0

            SymbolDictionary[i] = [midpoint, 
                                    slope_degrees, 
                                    fill(x_average, maximum(timesteps_to_model)), 
                                    fill(y_average, maximum(timesteps_to_model)), 
                                    fill(x_average, maximum(timesteps_to_model)), 
                                    fill(y_average, maximum(timesteps_to_model))]

        end       
    end

    return  SymbolDictionary
end


function CreatePlotsForOutageSimulatorModel(Multinode_Inputs, m_outagesimulator, DataDictionaryForEachNode, OutageLength_TimeSteps_Input, TimeStamp, TotalTimeSteps, NodeList, x, i, folder)
    # This function makes plots for each of the REopt nodes
    
    mkdir(folder*"/Outage_Simulation_Plots/OutageTimeStepsLength_$(OutageLength_TimeSteps_Input)_Simulation_Run_$(x)")
    
    for n in NodeList
        Plots.plot(JuMP.value.(m_outagesimulator[Symbol("dvPVToLoad_"*n)]), label = "PV to Load", linewidth = 3)
        Plots.plot!(JuMP.value.(m_outagesimulator[Symbol("dvGenToLoad_"*n)]), label = "Gen to Load", linewidth = 3)
        Plots.plot!(JuMP.value.(m_outagesimulator[Symbol("dvBatToLoad_"*n)]), label = "Battery to Load", linewidth = 3)
        Plots.plot!(JuMP.value.(m_outagesimulator[Symbol("dvBatToLoadWithEfficiency_"*n)]), label = "Battery to Load with Efficiency", linewidth = 3)
        Plots.plot!(JuMP.value.(m_outagesimulator[Symbol("dvGridToLoad_"*n)]), label = "Grid to Load", linewidth = 3)
        Plots.plot!(DataDictionaryForEachNode[n]["loads_kw"][i:(i+OutageLength_TimeSteps_Input-1)], label = "Total Load", linecolor = (:black), line = (:dash), linewidth = 3)
        Plots.xlabel!("Time Step") 
        Plots.ylabel!("Power (kW)") 
        Plots.title!("Node "*n*": Load Balance, outage timestep: "*string(i)*" of "*string(TotalTimeSteps))
        Plots.ylabel!("Power (kW)")
        Plots.savefig(folder*"/Outage_Simulation_Plots/OutageTimeStepsLength_$(OutageLength_TimeSteps_Input)_Simulation_Run_$(x)/Node_$(n)_Timestep_$(i)_Load_Balance_"*TimeStamp*".png")
    end 

    # Plots results for each node during the outage
    for n in NodeList
        # Plot the power export
        Plots.plot(JuMP.value.(m_outagesimulator[Symbol("dvPVToGrid_"*n)]), label = "PV to Grid")
        Plots.plot!(JuMP.value.(m_outagesimulator[Symbol("dvGenToGrid_"*n)]), label = "Gen to Grid")
        Plots.plot!(JuMP.value.(m_outagesimulator[Symbol("dvBatToGrid_"*n)]), label = "Battery to Grid")
        Plots.xlabel!("Time Step")
        Plots.ylabel!("Power (kW)")
        Plots.title!("Node "*n*": Power Export, outage timestep "*string(i)*" of "*string(TotalTimeSteps))
        Plots.ylabel!("Power (kW)")
        
        Plots.savefig(folder*"/Outage_Simulation_Plots/OutageTimeStepsLength_$(OutageLength_TimeSteps_Input)_Simulation_Run_$(x)/Node_$(n)_Timestep_$(i)_Power_Export_"*TimeStamp*".png")
    
        # Plot the battery flows
        Plots.plot(-JuMP.value.(m_outagesimulator[Symbol("dvBatToLoad_"*n)]), label = "Battery to Load")
        Plots.plot!(-JuMP.value.(m_outagesimulator[Symbol("dvBatToGrid_"*n)]), label = "Battery to Grid")
        Plots.plot!(JuMP.value.(m_outagesimulator[Symbol("dvGridToBat_"*n)]), label = "Grid to Battery")
        Plots.plot!(JuMP.value.(m_outagesimulator[Symbol("dvPVToBat_"*n)]), label = "PV to Battery")
        Plots.xlabel!("Time Step")
        Plots.ylabel!("Power (kW)")
        Plots.title!("Node "*n*": Battery Flows, outage "*string(i)*" of "*string(TotalTimeSteps))
        
            Plots.ylabel!("Power (kW)")
       
        Plots.savefig(folder*"/Outage_Simulation_Plots/OutageTimeStepsLength_$(OutageLength_TimeSteps_Input)_Simulation_Run_$(x)/Node_$(n)_Timestep_$(i)_Battery_Flows_"*TimeStamp*".png")
    
        # Plot the battery charge:
        Plots.plot(JuMP.value.(m_outagesimulator[Symbol("BatteryCharge_"*n)]), label = "Battery Charge")
        Plots.xlabel!("Time Step")
        Plots.ylabel!("Charge (kWh)")
        Plots.title!("Node "*n*": Battery Charge, outage "*string(i)*" of "*string(TotalTimeSteps))
        
           Plots.ylabel!("Power (kW)")
        
        Plots.savefig(folder*"/Outage_Simulation_Plots/OutageTimeStepsLength_$(OutageLength_TimeSteps_Input)_Simulation_Run_$(x)/Node_$(n)_Timestep_$(i)_Battery_Charge_"*TimeStamp*".png")
    end
end


function MapOutageSimulatorResultsPlots(Multinode_Inputs, outage_survival_results, outage_start_timesteps, TimeStamp, OutageLength_TimeSteps_Input, folder)
    # This function creates plots to summarize the outage simulation results

    indices_outage_survived = findall(x -> x==1, outage_survival_results) # Find indices of survived outages
    indices_outage_not_survived = findall(x -> x==0, outage_survival_results) # Find indices of non-survived outages

    print("\n the indices_outage_survived is: $(indices_outage_survived)")
    print("\n the outage_survival_results are: $(outage_survival_results)")
    outage_start_timesteps_survived = outage_start_timesteps[indices_outage_survived]
    outage_start_timesteps_not_survived = outage_start_timesteps[indices_outage_not_survived]

    time_of_day_survived = zeros(length(outage_start_timesteps_survived))
    day_of_year_survived = zeros(length(outage_start_timesteps_survived))
    time_of_day_not_survived = zeros(length(outage_start_timesteps_not_survived))
    day_of_year_not_survived = zeros(length(outage_start_timesteps_not_survived))

    for x in collect(1:length(outage_start_timesteps_survived))
        time_of_day_survived[x] = outage_start_timesteps_survived[x] % (24*Multinode_Inputs.time_steps_per_hour)
        day_of_year_survived[x] = ceil(outage_start_timesteps_survived[x] / (24*Multinode_Inputs.time_steps_per_hour))
    end

    for x in collect(1:length(outage_start_timesteps_not_survived))
        time_of_day_not_survived[x] = outage_start_timesteps_not_survived[x] % (24*Multinode_Inputs.time_steps_per_hour)
        day_of_year_not_survived[x] = ceil(outage_start_timesteps_not_survived[x] / (24*Multinode_Inputs.time_steps_per_hour))
    end        

    traces = PlotlyJS.GenericTrace[]
    push!(traces, PlotlyJS.histogram(x=time_of_day_survived, name="Survived", xbins_start=0, xbins_end=24, xbins_size=1))
    push!(traces, PlotlyJS.histogram(x=time_of_day_not_survived, name="Not Survived", xbins_start=0, xbins_end=24, xbins_size=1)) 
    layout = PlotlyJS.Layout(barmode="stack", title = "$(OutageLength_TimeSteps_Input) Time Step Outage: Distribution of Survival by time of day", xaxis_title = "Time of Day (hour)", yaxis_title="Count")
    p1 = PlotlyJS.plot(traces, layout)
    PlotlyJS.savefig(p1, folder*"/Outage_Simulation_Plots/Outage_Survival_Histogram_By_Time_Of_Day_$(OutageLength_TimeSteps_Input)_Timestep_Outage.html")
    #display(p1)
    
    traces = PlotlyJS.GenericTrace[]
    push!(traces, PlotlyJS.histogram(x=day_of_year_survived, name="Survived", xbins_start=0, xbins_end=371, xbins_size=7))
    push!(traces, PlotlyJS.histogram(x=day_of_year_not_survived, name="Not Survived", xbins_start=0, xbins_end=371, xbins_size=7)) 
    layout = PlotlyJS.Layout(barmode="stack", title = "$(OutageLength_TimeSteps_Input) Time Step Outage: Distribution of Survival by day of year", xaxis_title = "Day of Year (binned in weekly intervals)", yaxis_title="Count")
    p2 = PlotlyJS.plot(traces, layout)
    PlotlyJS.savefig(p2, folder*"/Outage_Simulation_Plots/Outage_Survival_Histogram_By_Day_Of_Year_$(OutageLength_TimeSteps_Input)_Timestep_Outage.html")
    #display(p2)
    
end




