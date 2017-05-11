module TrafficAssignment

# package code goes here
using LightGraphs, Optim, BinDeps


include("load_network.jl")
include("frank_wolfe.jl")


export
        load_ta_network, download_tntp, read_ta_network,
        ta_frank_wolfe,
        TA_Data



end # module
