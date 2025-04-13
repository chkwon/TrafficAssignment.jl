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
    is_in_degrees = (maximum(X) - minimum(X) < 1) && (maximum(Y) - minimum(Y) < 1)
    X_segments = collect(Iterators.flatten(zip(X[init_node], X[term_node])))
    Y_segments = collect(Iterators.flatten(zip(Y[init_node], Y[term_node])))
    fig = Figure()
    ax = Axis(
        fig[1, 1];
        title=instance_name,
        subtitle="$number_of_nodes nodes, $number_of_links links",
        aspect=is_in_degrees ? 90 / 180 : 1,
    )
    scatter!(ax, X, Y; color=:black)
    linesegments!(ax, X_segments, Y_segments; color=:black)
    return fig
end

project_mercator(x, y) = MapTiles.project((x, y), MapTiles.wgs84, MapTiles.web_mercator)

"""
$(SIGNATURES)

Plot a transportation network with Makie over OpenStreetMap tiles.

This function requires loading one of Makie's backends beforehand, as well as an internet connection. It assumes the node coordonates are given in degrees.
"""
function plot_network_osm(problem::TrafficAssignmentProblem)
    @assert !isnothing(problem.X)
    @assert !isnothing(problem.Y)
    (; instance_name, number_of_nodes, number_of_links, X, Y, init_node, term_node) =
        problem
    X_segments = collect(Iterators.flatten(zip(X[init_node], X[term_node])))
    Y_segments = collect(Iterators.flatten(zip(Y[init_node], Y[term_node])))
    xmin, xmax = extrema(X)
    ymin, ymax = extrema(Y)
    Δx = xmax - xmin
    Δy = ymax - ymin
    extent = Rect2f(xmin - 0.1Δx, ymin - 0.1Δy, 1.2Δx, 1.2Δy)
    tylermap = Tyler.Map(extent)
    sleep(1)
    ax = tylermap.axis
    node_coords = project_mercator.(X, Y)
    segment_coords = project_mercator.(X_segments, Y_segments)
    scatter!(ax, Point2f.(node_coords); color=:black)
    linesegments!(ax, Point2f.(segment_coords); color=:black)
    return tylermap
end
