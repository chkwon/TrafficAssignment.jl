const R = Float64

"""
$(TYPEDEF)

Instance of the static traffic assignment problem.

# Details

The link travel time is given by `travel_time = free_flow_time * ( 1 + b * (flow/capacity)^power)`.

The generalized cost is `cost = travel_time + toll_factor * toll + distance_factor * distance`.

# Fields

$(TYPEDFIELDS)
"""
@kwdef struct TrafficAssignmentProblem{
    B<:Union{R,SparseMatrixCSC{R,Int}},
    P<:Union{R,SparseMatrixCSC{R,Int}},
    T<:Union{Missing,SparseMatrixCSC{R,Int}},
    L<:Union{Missing,SparseMatrixCSC{Int,Int}},
    C<:Union{Nothing,Vector{Float64}},
    F<:Union{Nothing,SparseMatrixCSC{R,Int}},
}
    instance_name::String
    dataset_name::String = "TransportationNetworks"

    # network table
    number_of_zones::Int
    number_of_nodes::Int
    first_thru_node::Int
    number_of_links::Int

    capacity::SparseMatrixCSC{R,Int}
    link_length::SparseMatrixCSC{R,Int}
    free_flow_time::SparseMatrixCSC{R,Int}
    speed_limit::SparseMatrixCSC{R,Int}
    b::B
    power::P
    toll::T
    link_type::L

    # trips table
    total_od_flow::R
    travel_demand::Matrix{R}
    od_pairs::Vector{Tuple{Int,Int}}

    # node table
    node_longitude::C
    node_latitude::C
    valid_coordinates::Bool

    # flow table
    optimal_flow_volume::F
    optimal_flow_cost::F

    # cost parameters
    toll_factor::R
    distance_factor::R
end

function Base.show(io::IO, problem::TrafficAssignmentProblem)
    (; instance_name, number_of_nodes, number_of_links) = problem
    return print(
        io,
        "Traffic assignment problem on the $instance_name network with $number_of_nodes nodes and $number_of_links links",
    )
end

nb_nodes(problem::TrafficAssignmentProblem) = problem.number_of_nodes
nb_links(problem::TrafficAssignmentProblem) = problem.number_of_links
