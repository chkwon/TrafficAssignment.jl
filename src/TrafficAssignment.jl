module TrafficAssignment

# package code goes here
using LightGraphs, Optim


export
        load_ta_network,
        ta_frank_wolfe



include("load_network.jl")
include("frank_wolfe.jl")

end # module
