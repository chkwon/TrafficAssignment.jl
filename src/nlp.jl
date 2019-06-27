function ta_nlp(ta_data; method=:bfw, max_iter_no=2000, step=:exact, log=:off, tol=1e-3)

    setup_time = time()

    if log==:on
        println("-------------------------------------")
        println("Network Name: $(ta_data.network_name)")
        println("Method: $method")
        println("Line Search Step: $step")
        println("Maximum Interation Number: $max_iter_no")
        println("Tolerance for AEC: $tol")
        println("Number of processors: ", nprocs())
    end


    # unpacking data from ta_data
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
    od_pairs = ta_data.od_pairs

    toll_factor = ta_data.toll_factor
    distance_factor = ta_data.distance_factor

    best_objective = ta_data.best_objective




    # preparing a graph
    graph = create_graph(start_node, end_node)
    link_dic = sparse(start_node, end_node, collect(1:number_of_links))

    setup_time = time() - setup_time

    if log==:on
        println("Setup time = $setup_time seconds")
    end






    function BPR(x)
        # travel_time = free_flow_time .* ( 1.0 + B .* (x./capacity).^power )
        # generalized_cost = travel_time + toll_factor *toll + distance_factor * link_length
        # return generalized_cost

        bpr = similar(x)
        for i=1:length(bpr)
            bpr[i] = free_flow_time[i] * ( 1.0 + B[i] * (x[i]/capacity[i])^power[i] )
            bpr[i] += toll_factor * toll[i] + distance_factor * link_length[i]
        end
        return bpr
    end


    function objective(x)
        # value = free_flow_time .* ( x + B.* ( x.^(power+1)) ./ (capacity.^power) ./ (power+1))
        # return sum(value)

        sum = 0.0
        for i=1:length(x)
            sum += free_flow_time[i] * ( x[i] + B[i]* ( x[i]^(power[i]+1)) / (capacity[i]^power[i]) / (power[i]+1))
            sum += toll_factor *toll[i] + distance_factor * link_length[i]
        end
        return sum
    end








    links = Array{Tuple{Int64, Int64}}(undef, ta_data.number_of_links);
    for a=1:ta_data.number_of_links
        links[a] = (ta_data.start_node[a], ta_data.end_node[a]);
    end
    nodes = collect(1:number_of_nodes);
    q = zeros(length(nodes), length(od_pairs));

    for w=1:length(od_pairs)
        origin = od_pairs[w][1]
        destination = od_pairs[w][2]

        q[origin, w] = travel_demand[origin, destination]
        q[destination, w] = - travel_demand[origin, destination]
    end

    delta = zeros(length(nodes), length(links)) # node-arc incidence
    for i in 1:length(nodes), a in 1:length(links)
      if links[a][1]==i
        delta[i,a] = 1
      elseif links[a][2]==i
        delta[i,a] = -1
      end
    end


    m = Model(with_optimizer(Ipopt.Optimizer))

    @variable(m, x[a=1:length(links), w=1:length(od_pairs)] >=0 )
    @variable(m, v[a=1:length(links)] >= 0)

    @constraint(m, vc[a=1:length(links)], v[a] == sum( x[a,ww] for ww=1:length(od_pairs) ))

    @constraint(m, c5[i=1:length(nodes), w=1:length(od_pairs)],
            sum( delta[i,a] * x[a,w] for a=1:length(links) )
             == q[i,w]
        )

    @NLobjective(m, Min,
            sum(
free_flow_time[a] * ( v[a] + B[a]* ( v[a]^(power[a]+1)) / (capacity[a]^power[a]) / (power[a]+1))
+ toll_factor *toll[a] + distance_factor * link_length[a]
            for a=1:length(links)
        )
    )

    JuMP.optimize!(m)

    vv = JuMP.value.(v)

    @show vv
    @show BPR(vv)
    @show objective(vv)

    return vv, BPR(vv), JuMP.objective_value(m)


end
