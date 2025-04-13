module TrafficAssignmentMakieExt

using Makie
using Proj
using TrafficAssignment
import TrafficAssignment as TA

const WebMercator = "EPSG:3857"

function TrafficAssignment.plot_network(problem::TrafficAssignmentProblem; tiles=false)
    (;
        instance_name,
        number_of_nodes,
        number_of_links,
        node_longitude,
        node_latitude,
        valid_coordinates,
        init_node,
        term_node,
    ) = problem
    if valid_coordinates
        trans = Proj.Transformation("WGS84", WebMercator; always_xy=true)
        XY = trans.(collect(zip(node_longitude, node_latitude)))
        X, Y = first.(XY), last.(XY)
    else
        X, Y = node_longitude, node_latitude
    end
    X_segments = collect(Iterators.flatten(zip(X[init_node], X[term_node])))
    Y_segments = collect(Iterators.flatten(zip(Y[init_node], Y[term_node])))
    fig = Figure()
    ax = Axis(
        fig[1, 1];
        title=instance_name,
        subtitle="$number_of_nodes nodes, $number_of_links links",
        aspect=DataAspect(),
    )
    hidedecorations!(ax)
    hidespines!(ax)
    sc = scatter!(ax, Point2f.(collect(zip(X, Y))); color=:black)
    ls = linesegments!(ax, Point2f.(collect(zip(X_segments, Y_segments))); color=:black)
    if tiles && valid_coordinates
        TA.add_tiles!(fig, ax, node_longitude, node_latitude)
        translate!(sc, 0, 0, 10)
        translate!(ls, 0, 0, 10)
    end
    return fig
end

end
