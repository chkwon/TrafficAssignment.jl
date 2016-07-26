module TrafficAssignment

# package code goes here
using LightGraphs, Optim


include("load_network.jl")
include("frank_wolfe.jl")


export
        load_ta_network,
        ta_frank_wolfe



end # module
