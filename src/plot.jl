"""
$(SIGNATURES)

Plot a transportation network with Makie.

This function requires loading one of Makie's backends beforehand.
"""
function plot_network(problem::TrafficAssignmentProblem)
    @assert !isnothing(problem.X)
    @assert !isnothing(problem.Y)
    (; instance_name, number_of_nodes, number_of_links, X, Y, init_node, term_node) =
        problem
    fig = Figure()
    ax = Axis(
        fig[1, 1];
        title=instance_name,
        subtitle="$number_of_nodes nodes, $number_of_links links",
        xlabel="Longitude",
        ylabel="Latitude",
    )
    scatter!(ax, X, Y)
    X_segments = collect(Iterators.flatten(zip(X[init_node], X[term_node])))
    Y_segments = collect(Iterators.flatten(zip(Y[init_node], Y[term_node])))
    linesegments!(ax, X_segments, Y_segments)
    return fig
end
