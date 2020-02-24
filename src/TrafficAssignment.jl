module TrafficAssignment

# package code goes here
using LightGraphs, Optim, BinDeps
using Distributed, Printf, LinearAlgebra, SparseArrays

TNTP_SHA = "f730be5e3366e910bb7e9ada4665d32e9cbc219b"


include("load_network.jl")
include("frank_wolfe.jl")


export
        load_ta_network, download_tntp, read_ta_network, summarize_ta_data,
        ta_frank_wolfe,
        TA_Data



end # module
