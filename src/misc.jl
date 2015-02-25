



function create_graph(start_node, end_node)
    @assert Base.length(start_node)==Base.length(end_node)

    no_node = max(maximum(start_node), maximum(end_node))
    no_arc = Base.length(start_node)

    graph = simple_inclist(no_node)
    for i=1:no_arc
        add_edge!(graph, start_node[i], end_node[i])
    end
    return graph
end



function get_vector(state, origin, destination, link_dic)
    current = destination
    parent = -1
    x = zeros(Int, maximum(link_dic))

    while parent != origin
        parent = state.parents[current]

        link_idx = link_dic[parent,current]

        if link_idx != 0
            x[link_idx] = 1
        end

        current = parent
    end

    return x
end









# function get_shortest_path(start_node, end_node, link_length, origin, destination)
#     @assert Base.length(start_node)==Base.length(end_node)
#     @assert Base.length(start_node)==Base.length(link_length)
#
#     graph = create_graph(start_node, end_node)
#
#     state = dijkstra_shortest_paths(graph, link_length, origin)
#
#     path = get_path(state, origin, destination)
#     x = get_vector(path, start_node, end_node)
#
#     return path, x
# end
#
# function get_vector(state, origin, destination, start_node, end_node)
#     current = destination
#     parent = -1
#     x = zeros(Int, Base.length(start_node))
#
#     while parent != origin
#         parent = state.parents[current]
#
#         for j=1:Base.length(start_node)
#             if start_node[j]==parent && end_node[j]==current
#                 x[j] = 1
#                 break
#             end
#         end
#
#         current = parent
#     end
#
#     return x
# end
