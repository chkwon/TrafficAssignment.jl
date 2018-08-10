module TrafficAssignment

# package code goes here
using LightGraphs, Optim, BinDeps
using Distributed, Printf, LinearAlgebra, SparseArrays

TNTP_SHA = "ca933f74c03af688dfffa33f4b00826cba672479"


include("load_network.jl")
include("frank_wolfe.jl")


export
        load_ta_network, download_tntp, read_ta_network,
        ta_frank_wolfe,
        TA_Data



end # module
