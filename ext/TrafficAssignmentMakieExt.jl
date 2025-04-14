module TrafficAssignmentMakieExt

using Makie
using Proj
using SparseArrays
using TrafficAssignment
import TrafficAssignment as TA

const WebMercator = "EPSG:3857"

function TrafficAssignment.plot_network(
    problem::TrafficAssignmentProblem; zones=false, tiles=false
)
    (;
        instance_name,
        real_nodes,
        zone_nodes,
        node_coord,
        valid_longitude_latitude,
        link_capacity,
    ) = problem
    if valid_longitude_latitude
        trans = Proj.Transformation("WGS84", WebMercator; always_xy=true)
        XY = trans.(node_coord)
        X, Y = first.(XY), last.(XY)
    else
        X, Y = first.(node_coord), last.(node_coord)
    end
    I, J, _ = findnz(link_capacity)
    if !zones
        IJ_filtered = [(i, j) for (i, j) in zip(I, J) if i in real_nodes && j in real_nodes]
        I = first.(IJ_filtered)
        J = last.(IJ_filtered)
    end
    X_segments = collect(Iterators.flatten(zip(X[I], X[J])))
    Y_segments = collect(Iterators.flatten(zip(Y[I], Y[J])))
    Δx = maximum(X) - minimum(X)
    Δy = maximum(Y) - minimum(Y)
    Δmax = max(Δx, Δy)
    fig = Figure(; size=(700 / Δmax) .* (Δx, Δy))
    ax = Axis(
        fig[1, 1];
        title=instance_name,
        subtitle="$(nb_nodes(problem)) nodes, $(nb_links(problem)) links",
        aspect=DataAspect(),
    )
    hidedecorations!(ax)
    hidespines!(ax)
    ls = linesegments!(ax, Point2f.(collect(zip(X_segments, Y_segments))); color=:black)
    sc1 = scatter!(ax, Point2f.(collect(zip(X[real_nodes], Y[real_nodes]))); color=:black)
    if zones
        sc2 = scatter!(
            ax,
            Point2f.(collect(zip(X[zone_nodes], Y[zone_nodes])));
            color=:red,
            marker=:diamond,
        )
    end
    if tiles && valid_longitude_latitude
        TA.add_tiles!(fig, ax, node_coord)
        translate!(sc1, 0, 0, 10)
        zones && translate!(sc2, 0, 0, 10)
        translate!(ls, 0, 0, 10)
    end
    return fig
end

end
