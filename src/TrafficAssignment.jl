"""
    TrafficAssignment

A Julia package for studying traffic assignment problems, using data from [https://github.com/bstabler/TransportationNetworks](https://github.com/bstabler/TransportationNetworks).
"""
module TrafficAssignment

# outside packages
using BinDeps: unpack_cmd
using DataDeps: DataDeps, DataDep, @datadep_str
using DataFrames
using DocStringExtensions
using Graphs
using Optim
using OrderedCollections
# standard libraries
using Distributed
using Printf
using LinearAlgebra
using SparseArrays

include("load_network.jl")
include("frank_wolfe.jl")

# latest commit to bstabler/TransportationNetworks: August 2nd, 2023
const LAST_COMMIT_SHA = "375e0da93858c547230c5cf9ea8a96de4ccff29e"  # to update

function __init__()
    name = "TransportationNetworks"
    message = "TransportationNetworks is a repository of real-life road networks, used to study the Traffic Assignment Problem. It is available at <https://github.com/bstabler/TransportationNetworks>."
    remote_path = "https://github.com/bstabler/TransportationNetworks/archive/$(LAST_COMMIT_SHA).zip"
    hash = "3ef8f870c14fc189a31d34266140d21883ce020cb8847788b1e2caea1e00a734"
    datadep = DataDep(
        name,
        message,
        remote_path,
        hash;
        fetch_method=DataDeps.fetch_default,
        post_fetch_method=post_fetch_method,
    )
    DataDeps.register(datadep)
    return nothing
end

function post_fetch_method(zip_file)
    DataDeps.unpack(zip_file; keep_originals=false)
    # decompress potential zip files inside each instance
    for instance_dir in readdir("TransportationNetworks-$LAST_COMMIT_SHA"; join=true)
        isdir(instance_dir) || continue
        for potential_zip_file in readdir(instance_dir; join=true)
            if endswith(potential_zip_file, ".zip")
                run(unpack_cmd(potential_zip_file, instance_dir, ".zip", ""))
            end
        end
    end
end

function datapath()
    return joinpath(
        datadep"TransportationNetworks", "TransportationNetworks-$LAST_COMMIT_SHA"
    )
end

function datapath(instance_name::AbstractString)
    return joinpath(
        datadep"TransportationNetworks",
        "TransportationNetworks-$LAST_COMMIT_SHA",
        instance_name,
    )
end

export TrafficAssignmentProblem, list_instances, summarize_instances, solve_frank_wolfe

end # module
