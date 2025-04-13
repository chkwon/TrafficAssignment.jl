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
    C<:Union{Nothing,Vector{Float64}},F<:Union{Nothing,SparseMatrixCSC{Float64,Int}}
}
    instance_name::String

    # network table
    number_of_zones::Int
    number_of_nodes::Int
    first_thru_node::Int
    number_of_links::Int

    init_node::Vector{Int}
    term_node::Vector{Int}
    capacity::SparseMatrixCSC{Float64,Int}
    link_length::SparseMatrixCSC{Float64,Int}
    free_flow_time::SparseMatrixCSC{Float64,Int}
    b::SparseMatrixCSC{Float64,Int}
    power::SparseMatrixCSC{Float64,Int}
    speed_limit::SparseMatrixCSC{Float64,Int}
    toll::SparseMatrixCSC{Float64,Int}
    link_type::SparseMatrixCSC{Int,Int}

    # trips table
    total_od_flow::Float64
    travel_demand::Matrix{Float64}
    od_pairs::Vector{Tuple{Int,Int}}

    # node table
    X::C
    Y::C

    # flow table
    optimal_flow_volume::F
    optimal_flow_cost::F

    # cost parameters
    toll_factor::Float64
    distance_factor::Float64
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
