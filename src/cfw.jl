# Conjugate Direction Frank-Wolfe Method
# CFW in Mitradijieva and Lindberg (2013)

# required packages: Graphs, Optim

include("misc.jl")


function ta_fw(ta_data, method)

    # data
    network_name = ta_data.network_name

    number_of_zones = ta_data.number_of_zones
    number_of_nodes = ta_data.number_of_nodes
    first_thru_node = ta_data.first_thru_node
    number_of_links = ta_data.number_of_links

    start_node = ta_data.start_node
    end_node = ta_data.end_node
    capacity = ta_data.capacity
    link_length = ta_data.link_length

    free_flow_time = ta_data.free_flow_time
    B = ta_data.B
    power = ta_data.power
    speed_limit = ta_data.speed_limit
    toll = ta_data.toll
    link_type = ta_data.link_type
    number_of_zones = ta_data.number_of_zones
    total_od_flow = ta_data.total_od_flow
    travel_demand = ta_data.travel_demand


    function BPR(x)
        travel_time = free_flow_time .* ( 1.0 + B .* (x./capacity).^power )
        return travel_time
    end

    function all_or_nothing(travel_time)
        state = []
        path = []
        v = []
        x = zeros(size(start_node))

        for r=1:size(travel_demand)[1]
            # for each origin node r, find shortest paths to all destination nodes
            state = dijkstra_shortest_paths(graph, travel_time, r)

            for s=1:size(travel_demand)[2]
                # for each destination node s, find the shortest-path vector
                v = get_vector(state, r, s, start_node, end_node)

                # load travel demand
                x = x + v * travel_demand[r,s]
            end
        end

        return x
    end






    # Initialization
    graph = create_graph(start_node, end_node)

    # Finding a starting feasible solution
    travel_time = BPR(zeros(number_of_links))
    x0 = all_or_nothing(travel_time)

    # Conjugate Frank-Wolfe Iteration
    xk = x0
    lambdak = 0
    yk_FW = x0
    sk_CFW = yk_FW
    Hk = []

    dk_FW = []
    dk_bar = []
    dk_CFW = []
    dk = []

    alphak = 0
    Nk = 0
    Dk = 0



    function objective(x)
        value = free_flow_time .* ( x + B.* ( x.^(power+1)) ./ (capacity.^power) ./ (power+1))
        return sum(value)
    end

    function fk(lambda)
        x = xk+lambda*dk
        value = objective(x)
        return value
    end

    function lower_bound_k(x, xk)
        value = objective(xk) + dot( BPR(xk), ( x - xk) )
    end

    function hessian(x)
        no_arc = Base.length(start_node)

        h = zeros(no_arc,no_arc)

        for i=1:no_arc
            h[i,i] = free_flow_time[i] * B[i] * power[i] * *(x[i]^(power[i]-1)) / (capacity[i]^power[i])
        end

        return h

        #Link travel time = free flow time * ( 1 + B * (flow/capacity)^Power ).
    end






    for k=1:35700
        # Finding yk
        travel_time = BPR(xk)
        yk_FW = all_or_nothing(travel_time)
        if k==1
            sk_CFW = yk_FW
        end

        # Basic Frank-Wolfe Direction
        dk_FW = yk_FW - xk

        # Finding a feasible direction
        if method == "FW" # Original Frank-Wolfe
            dk = dk_FW
        elseif method == "CFW" # Conjugate Direction F-W
            dk_bar = sk_CFW - xk

            # These computations involving Hessian may be improved,
            # since all off-diagonal elements are zero.
            Hk = hessian(xk)
            Nk = dot( dk_bar, Hk * dk_FW )
            Dk = dot( dk_bar, Hk * (dk_FW - dk_bar) )

            delta = 0.2 # What value should I use?
            alphak = 0
            if Dk !=0 && 0 <=Nk/Dk <= 1-delta
                alphak = Nk/Dk
            elseif Dk !=0 && Nk/Dk > 1-delta
                alphak = 1-delta
            else
                alphak = 0
            end

            sk_CFW = alphak * sk_CFW + (1-alphak) * yk_FW
            dk_CFW = sk_CFW - xk

            # Feasible Direction to Use
            dk = dk_CFW
        else
            error("The type of Frank-Wolfe method is specified incorrectly. Use FW, CFW, or BFW.")
        end

        # Line Search from xk in the direction dk
        optk = optimize(fk, 0.0, 1.0, method = :golden_section)
        lambdak = optk.minimum

        new_x = xk + lambdak*dk

        println("k=$k,\t lambdak=$lambdak,\t objective=$(objective(xk))")

        error = norm(new_x - xk) / norm(xk)
        # println("k=$k,\t error=$error")

        # if error < 1e-8
        #     break
        # end

        best_known_obj = 4.231335287107440e6

        if objective(xk) < 1.01 * best_known_obj
            break
        end

        # Update x
        xk = new_x

    end


    return xk, travel_time, objective(xk)

end





#
