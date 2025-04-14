module TrafficAssignmentTylerExt

using Makie
using TrafficAssignment
using Tyler

function TrafficAssignment.add_tiles!(fig, ax, node_coord)
    node_longitude, node_latitude = first.(node_coord), last.(node_coord)
    minlong, maxlong = extrema(node_longitude)
    minlat, maxlat = extrema(node_latitude)
    Δlong = maxlong - minlong
    Δlat = maxlat - minlat
    extent = Rect2f(minlong - 0.1Δlong, minlat - 0.1Δlat, 1.2Δlong, 1.2Δlat)
    tylermap = Tyler.Map(extent; figure=fig, axis=ax)
    wait(tylermap)
    return nothing
end

end
