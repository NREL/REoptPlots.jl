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
function efc(d)
    if "EFC" in keys(d["Storage"])
        return d["Storage"]["EFC"]
    end
    # TODO use REoptInputs for initial SOC 
    power = diff(append!([0.5], d["Storage"]["year_one_soc_series_pct"]))
    abs_power = abs.(power)
    efc = zeros(365)
    # TODO handle time resolution other than hourly
    for d in 1:365
        ts0 = Int(round((24 * (d - 1) + 1)))
        tsF = Int(round(24 * d))
        efc[d] = sum(abs_power[ts0:tsF])/2
    end
    return efc
end


function plot_violin_compare_soc_efc(d1::Dict, d2::Dict; 
    title="Violin distribution of SOC and EFC",
    name_soc_1="SOC no degr.",
    name_soc_2="SOC with degr.",
    name_efc_1="EFC no degr.",
    name_efc_2="EFC with degr.",
    )

    soc1 = d1["Storage"]["year_one_soc_series_pct"]
    soc2 = d2["Storage"]["year_one_soc_series_pct"]

    efc1 = efc(d1)
    efc2 = efc(d2)

    traces = [
        PlotlyJS.violin(
            y=soc1, 
            side="negative", 
            x=repeat(["SOC"], length(soc1)), 
            spanmode="hard",
            points=false,
            name=name_soc_1,
        ), 
        PlotlyJS.violin(
            y=soc2, 
            side="positive", 
            x=repeat(["SOC"], length(soc2)), 
            spanmode="hard",
            points=false,
            name=name_soc_2,
        ), 
        PlotlyJS.violin(
            y=efc1, 
            side="negative", 
            x=repeat(["EFC"], length(efc1)), 
            spanmode="hard",
            points=false,
            name=name_efc_1,
        ), 
        PlotlyJS.violin(
            y=efc2, 
            side="positive", 
            x=repeat(["EFC"], length(efc2)), 
            spanmode="hard",
            points=false,
            name=name_efc_2,
        ), 
    ]

    layout = PlotlyJS.Layout(
        title_text = title,
        font_size=20,
        # tickfont_size=20
    )

    PlotlyJS.plot(traces, layout)

end



