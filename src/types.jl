"""
$(TYPEDEF)

Instance of the static traffic assignment problem.

# Details

The link travel time is given by the formula of the Bureau of Public Roads (BPR):

    t = t0 * (1 + α * (f/c)^β)

where

  - `t` is the travel time
  - `t0` is the free flow time
  - `f` is the flow along the link
  - `c` is the link capacity
  - `α` is a multiplicative coefficient (often taken to be `0.15`)
  - `β` is an exponent (often taken to be `4`)

# Fields

$(TYPEDFIELDS)
"""
@kwdef struct TrafficAssignmentProblem{
    Coord<:Union{Missing,Vector{<:NTuple{2,<:Number}}},
    Capa<:SparseMatrixCSC{<:Number},
    Length<:SparseMatrixCSC{<:Number},
    Free<:SparseMatrixCSC{<:Number},
    Speed<:SparseMatrixCSC{<:Number},
    BPRMult<:Union{Number,SparseMatrixCSC{<:Number}},
    BPRPow<:Union{Number,SparseMatrixCSC{<:Number}},
    Toll<:Union{Missing,SparseMatrixCSC{<:Number}},
    LinkT<:Union{Missing,SparseMatrixCSC{<:Integer}},
    Flow<:Union{Missing,SparseMatrixCSC{<:Number}},
    Dem<:Number,
    TF<:Union{Number,Missing},
    DF<:Union{Number,Missing},
}
    "name of the dataset, one of $DATASET_NAMES"
    dataset_name::String
    "name of the instance (subfolder inside the dataset)"
    instance_name::String

    # nodes
    "number of nodes in the network (nodes are numbered from `1` to `nb_nodes`)"
    nb_nodes::Int
    "number of directed links in the network"
    nb_links::Int
    "interval of nodes that correspond to real intersections"
    real_nodes::UnitRange{Int}
    "interval of nodes that correspond to artificial zones"
    zone_nodes::UnitRange{Int}
    "coordinates of the nodes for plotting"
    node_coord::Coord
    "whether `node_coord` corresponds to the longitude and latitude"
    valid_longitude_latitude::Bool

    # links
    "matrix of link capacities (`c` in the BPR formula)"
    link_capacity::Capa
    "matrix of link lengths"
    link_length::Length
    "matrix of link free flow times (`t0` in the BPR formula)"
    link_free_flow_time::Free
    "matrix of link speed limits"
    link_speed_limit::Speed
    "link multiplicative factors `α` in the BPR formula, either a single scalar or a matrix"
    link_bpr_mult::BPRMult
    "link exponents `β` in the BPR formula, either a single scalar or a matrix"
    link_bpr_power::BPRPow
    "matrix of link tolls"
    link_toll::Toll
    "matrix of link types"
    link_type::LinkT

    # demand
    "demand by OD pair"
    demand::Dict{Tuple{Int,Int},Dem}

    # cost parameters
    "conversion factor turning toll costs into temporal costs, expressed in time/toll"
    toll_factor::TF
    "conversion factor turning distance costs into temporal costs, expressed in time/length"
    distance_factor::DF

    # solution
    "provided matrix of optimal link flows"
    optimal_flow::Flow
end

function Base.show(io::IO, problem::TrafficAssignmentProblem)
    (; instance_name) = problem
    return print(
        io,
        "Traffic assignment problem on the $instance_name network with $(nb_nodes(problem)) nodes, $(nb_links(problem)) links and $(nb_zones(problem)) zones",
    )
end

"""
    nb_nodes(problem::TrafficAssignmentProblem)

Return the number of nodes in the network (including zone nodes).
"""
nb_nodes(problem::TrafficAssignmentProblem) = problem.nb_nodes

"""
    nb_links(problem::TrafficAssignmentProblem)

Return the number of links in the network (including links to and from zone nodes).
"""
nb_links(problem::TrafficAssignmentProblem) = problem.nb_links

"""
    nb_zones(problem::TrafficAssignment)

Return the number of fake nodes in the network that represent zones.
"""
nb_zones(problem::TrafficAssignmentProblem) = length(problem.zone_nodes)
