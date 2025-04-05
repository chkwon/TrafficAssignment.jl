
function TA_dijkstra_shortest_paths(
    graph, travel_time, origin, init_node, term_node, first_thru_node
)
    no_node = nv(graph)
    no_arc = ne(graph)

    distmx = Inf*ones(no_node, no_node)
    for i in 1:no_arc
        if term_node[i] >= first_thru_node
            distmx[init_node[i], term_node[i]] = travel_time[i]
        end
    end

    state = dijkstra_shortest_paths(graph, origin, distmx)
    return state
end

function TA_dijkstra_shortest_paths(graph, travel_time, origin, init_node, term_node)
    no_node = nv(graph)
    no_arc = ne(graph)

    distmx = Inf*ones(no_node, no_node)
    for i in 1:no_arc
        distmx[init_node[i], term_node[i]] = travel_time[i]
    end

    state = dijkstra_shortest_paths(graph, origin, distmx)
    return state
end

function create_graph(init_node, term_node)
    @assert Base.length(init_node)==Base.length(term_node)

    no_node = max(maximum(init_node), maximum(term_node))
    no_arc = Base.length(init_node)

    graph = DiGraph(no_node)
    for i in 1:no_arc
        add_edge!(graph, init_node[i], term_node[i])
    end
    return graph
end

function get_vector(state, origin, destination, link_dic)
    current = destination
    parent = -1
    x = zeros(Int, maximum(link_dic))

    while parent != origin && origin != destination && current != 0
        parent = state.parents[current]

        # println("origin=$origin, destination=$destination, parent=$parent, current=$current")

        if parent != 0
            link_idx = link_dic[parent, current]
            if link_idx != 0
                x[link_idx] = 1
            end
        end

        current = parent
    end

    return x
end

function add_demand_vector!(x, demand, state, origin, destination, link_dic)
    current = destination
    parent = -1

    while parent != origin && origin != destination && current != 0
        parent = state.parents[current]

        if parent != 0
            link_idx = link_dic[parent, current]
            if link_idx != 0
                x[link_idx] += demand
            end
        end

        current = parent
    end
end

# function get_shortest_path(init_node, term_node, link_length, origin, destination)
#     @assert Base.length(init_node)==Base.length(term_node)
#     @assert Base.length(init_node)==Base.length(link_length)
#
#     graph = create_graph(init_node, term_node)
#
#     state = dijkstra_shortest_paths(graph, link_length, origin)
#
#     path = get_path(state, origin, destination)
#     x = get_vector(path, init_node, term_node)
#
#     return path, x
# end
#
# function get_vector(state, origin, destination, init_node, term_node)
#     current = destination
#     parent = -1
#     x = zeros(Int, Base.length(init_node))
#
#     while parent != origin
#         parent = state.parents[current]
#
#         for j=1:Base.length(init_node)
#             if init_node[j]==parent && term_node[j]==current
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
