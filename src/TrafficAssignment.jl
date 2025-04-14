"""
    TrafficAssignment

A Julia package for studying traffic assignment problems, using instaces from two datasets:

  - `"TransportationNetworks"`, available at [https://github.com/bstabler/TransportationNetworks](https://github.com/bstabler/TransportationNetworks)
  - `"UnifiedTrafficDataset"`, available at [https://figshare.com/articles/dataset/A_unified_and_validated_traffic_dataset_for_20_U_S_cities/24235696](https://figshare.com/articles/dataset/A_unified_and_validated_traffic_dataset_for_20_U_S_cities/24235696)
"""
module TrafficAssignment

const DATASET_NAMES = ["TransportationNetworks", "UnifiedTrafficDataset"]

# outside packages
using BinDeps: unpack_cmd
using CSV: CSV
using DataDeps: DataDeps, DataDep, @datadep_str
using DataFrames
using DataFramesMeta: @rsubset
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
export datapath
export nb_nodes, nb_links, nb_zones
export list_instances, summarize_instances
export solve_frank_wolfe, social_cost
export plot_network

end # module
