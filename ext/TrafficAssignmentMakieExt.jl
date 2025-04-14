module TrafficAssignmentMakieExt

using Makie
using Proj
using SparseArrays
using TrafficAssignment
import TrafficAssignment as TA

const WebMercator = "EPSG:3857"

function TrafficAssignment.plot_network(problem::TrafficAssignmentProblem; tiles=false)
    (;
        instance_name,
        number_of_nodes,
        number_of_links,
        capacity,
        node_x,
        node_y,
        valid_longitude_latitude,
    ) = problem
    if valid_longitude_latitude
        node_longitude, node_latitude = node_x, node_y
        trans = Proj.Transformation("WGS84", WebMercator; always_xy=true)
        XY = trans.(collect(zip(node_longitude, node_latitude)))
        X, Y = first.(XY), last.(XY)
    else
        X, Y = node_x, node_y
    end
    I, J, _ = findnz(capacity)
    X_segments = collect(Iterators.flatten(zip(X[I], X[J])))
    Y_segments = collect(Iterators.flatten(zip(Y[I], Y[J])))
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
    if tiles && valid_longitude_latitude
        node_longitude, node_latitude = node_x, node_y
        TA.add_tiles!(fig, ax, node_longitude, node_latitude)
        translate!(sc, 0, 0, 10)
        translate!(ls, 0, 0, 10)
    end
    return fig
end

end
