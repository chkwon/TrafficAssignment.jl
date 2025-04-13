"""
    TrafficAssignment

A Julia package for studying traffic assignment problems, using data from [https://github.com/bstabler/TransportationNetworks](https://github.com/bstabler/TransportationNetworks).
"""
module TrafficAssignment

# outside packages
using BinDeps: unpack_cmd
using CSV: CSV
using DataDeps: DataDeps, DataDep, @datadep_str
using DataFrames
using DocStringExtensions
using FrankWolfe
using Graphs
using OrderedCollections
using Proj
using SimpleWeightedGraphs
# standard libraries
using Distributed
using Printf
using LinearAlgebra
using SparseArrays

include("download.jl")
include("types.jl")
include("read.jl")
include("solve.jl")
include("plot.jl")

export TrafficAssignmentProblem
export list_instances, summarize_instances
export solve_frank_wolfe, social_cost
export plot_network

end # module
