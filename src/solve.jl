mynz(A::SparseMatrixCSC) = nonzeros(A)
mynz(a::Number) = a

function sparse_by_link(problem::TrafficAssignmentProblem, nzval::AbstractVector)
    A = problem.free_flow_time
    return SparseMatrixCSC(A.m, A.n, A.colptr, A.rowval, nzval)
end

function link_travel_time(problem::TrafficAssignmentProblem, flow::AbstractMatrix)
    (; free_flow_time, b, capacity, power) = problem
    travel_time_nz =
        mynz(free_flow_time) .*
        (1 .+ mynz(b) .* (mynz(flow) ./ mynz(capacity)) .^ mynz(power))
    return sparse_by_link(problem, travel_time_nz)
end

function link_travel_time_integral(problem::TrafficAssignmentProblem, flow::AbstractMatrix)
    (; free_flow_time, b, capacity, power) = problem
    travel_time_integral_nz =
        mynz(free_flow_time) .* (
            mynz(flow) .+
            ((mynz(b) .* mynz(capacity)) ./ (mynz(power) .+ 1)) .*
            (mynz(flow) ./ mynz(capacity)) .^ (mynz(power) .+ 1)
        )
    return sparse_by_link(problem, travel_time_integral_nz)
end

function other_link_cost(problem::TrafficAssignmentProblem)
    (; toll, toll_factor, distance, distance_factor) = problem
    return @. (toll * toll_factor) + (distance * distance_factor)
end

function objective(problem::TrafficAssignmentProblem, flow_vec::AbstractVector)
    flow = sparse_by_link(problem, flow_vec)
    return objective(problem, flow)
end

function objective(problem::TrafficAssignmentProblem, flow::AbstractMatrix)
    obj = sum(link_travel_time_integral(problem, flow))
    return obj
end

function objective_gradient(problem::TrafficAssignmentProblem, flow_vec::AbstractVector)
    flow = sparse_by_link(problem, flow_vec)
    return mynz(link_travel_time(problem, flow))
end

"""
$(SIGNATURES)

Compute the social cost induced by a matrix of link flows.
"""
function social_cost(problem::TrafficAssignmentProblem, flow::AbstractMatrix)
    return dot(link_travel_time(problem, flow), flow)
end

struct ShortestPathOracle{P<:TrafficAssignmentProblem,H} <:
       FrankWolfe.LinearMinimizationOracle
    problem::P
    heuristic_dists::H
end

function ShortestPathOracle(problem::TrafficAssignmentProblem)
    cost = problem.free_flow_time
    graph = SimpleWeightedDiGraph(cost)
    # TODO: optimize with reverse Dijkstra from destinations only
    johnson = johnson_shortest_paths(graph)
    return ShortestPathOracle(problem, johnson.dists)
end

function FrankWolfe.compute_extreme_point(
    spo::ShortestPathOracle, cost_vec::AbstractVector; kwargs...
)
    yield()
    (; problem, heuristic_dists) = spo
    (; travel_demand) = problem
    cost = sparse_by_link(problem, cost_vec)
    graph = SimpleWeightedDiGraph(cost)
    flow = similar(cost)
    flow .= 0
    for (o, d) in keys(travel_demand)
        path = a_star(graph, o, d, weights(graph), v -> heuristic_dists[v, d])
        for edge in path
            flow[src(edge), dst(edge)] += travel_demand[o, d]
        end
    end
    return mynz(flow)
end

"""
$(SIGNATURES)

Solve a traffic assignment problem using an algorithm from the FrankWolfe library.

Keyword arguments are passed to `frank_wolfe_alg`.
"""
function solve_frank_wolfe(
    problem::TrafficAssignmentProblem,
    frank_wolfe_alg::A=frank_wolfe;
    verbose::Bool=true,
    kwargs...,
) where {A}
    lmo = ShortestPathOracle(problem)
    f(cost_vec) = objective(problem, cost_vec)
    function grad!(storage, cost_vec)
        grad = objective_gradient(problem, cost_vec)
        return copyto!(storage, grad)
    end
    direction_init = zeros(Float64, nb_links(problem))
    flow_init = FrankWolfe.compute_extreme_point(lmo, direction_init)
    flow_opt, _ = frank_wolfe_alg(f, grad!, lmo, flow_init; verbose, kwargs...)
    return sparse_by_link(problem, flow_opt)
end
