# Frank-Wolfe Methods
# CFW and BFW in Mitradijieva and Lindberg (2013)

# required packages: Graphs, Optim

include("misc.jl")

function BPR(x::Vector{Float64}, td::TA_Data)
    bpr = similar(x)
    for i in 1:length(bpr)
        bpr[i] = td.free_flow_time[i] * (1.0 + td.b[i] * (x[i]/td.capacity[i])^td.power[i])
        bpr[i] += td.toll_factor * td.toll[i] + td.distance_factor * td.link_length[i]
    end
    return bpr
end

gradient = BPR

function objective(x::Vector{Float64}, td::TA_Data)
    # value = free_flow_time .* ( x + b.* ( x.^(power+1)) ./ (capacity.^power) ./ (power+1))
    # return sum(value)

    sum = 0.0
    for i in 1:length(x)
        sum +=
            td.free_flow_time[i] * (
                x[i] +
                td.b[i] * (x[i]^(td.power[i]+1)) / (td.capacity[i]^td.power[i]) /
                (td.power[i]+1)
            )
        sum += td.toll_factor * td.toll[i] + td.distance_factor * td.link_length[i]
    end
    return sum
end

function hessian(x::Vector{Float64}, td::TA_Data)
    no_arc = length(td.init_node)

    h = zeros(no_arc, no_arc)
    h_diag = hessian_diag(x, td)

    for i in 1:no_arc
        h[i, i] = h_diag[i]
    end

    return h

    #Link travel time = free flow time * ( 1 + b * (flow/capacity)^Power ).
end

function hessian_diag(x::Vector{Float64}, td::TA_Data)
    h_diag = Array{Float64}(undef, length(x))
    for i in 1:length(x)
        if td.power[i] >= 1.0
            h_diag[i] =
                td.free_flow_time[i] * td.b[i] * td.power[i] * (x[i]^(td.power[i]-1)) /
                (td.capacity[i]^td.power[i])
        else
            h_diag[i] = 0 # Some cases, power is zero.
        end
    end
    # h_diag = free_flow_time .* b .* power .* (x.^(power-1)) ./ (capacity.^power)

    return h_diag
    #Link travel time = free flow time * ( 1 + b * (flow/capacity)^Power ).
end

function all_or_nothing_single(travel_time::Vector{Float64}, td::TA_Data, graph, link_dic)
    local state::Graphs.DijkstraState{Float64,Int}
    x = zeros(size(td.init_node))

    for r in 1:size(td.travel_demand)[1]
        # for each origin node r, find shortest paths to all destination nodes
        state = TA_dijkstra_shortest_paths(
            graph, travel_time, r, td.init_node, td.term_node, td.first_thru_node
        )

        for s in 1:size(td.travel_demand)[2]
            # for each destination node s, find the shortest-path vector
            # load travel demand
            # x = x + travel_demand[r,s] * get_vector(state, r, s, link_dic)
            add_demand_vector!(x, td.travel_demand[r, s], state, r, s, link_dic)
        end
    end
    return x
end

# parallel computing version
# function all_or_nothing_parallel(travel_time::Vector{Float64}, td::TA_Data, graph, link_dic)
#     local state::Graphs.DijkstraState{Float64, Int}
#     vv = zeros(size(td.init_node))
#     x = zeros(size(td.init_node))

#     x = x .+ @distributed (+) for r in 1:size(td.travel_demand)[1]
#         # for each origin node r, find shortest paths to all destination nodes
#         # if there is any travel demand starting from node r.
#         vv = zeros(size(td.init_node))

#         if sum(td.travel_demand, dims=2)[r] > 0.0
#             state = TA_dijkstra_shortest_paths(graph, travel_time, r, td.init_node, td.term_node, td.first_thru_node)

#             for s=1:size(td.travel_demand)[2]
#                 # for each destination node s, find the shortest-path vector
#                 # v = get_vector(state, r, s, init_node, term_node)

#                 if td.travel_demand[r,s] > 0.0
#                     # load travel demand
#                     # vv = vv + travel_demand[r,s] * get_vector(state, r, s, link_dic)
#                     add_demand_vector!(vv, td.travel_demand[r,s], state, r, s, link_dic)
#                 end
#             end

#         end

#         vv
#     end

#     return x
# end

function all_or_nothing(travel_time::Vector{Float64}, td::TA_Data, graph, link_dic)
    # if nprocs() > 1 # if multiple CPU processes are available
    #     return all_or_nothing_parallel(travel_time, td, graph, link_dic)
    # else
    #     return all_or_nothing_single(travel_time, td, graph, link_dic)
    #     # when nprocs()==1, using @distributed just adds unnecessary setup time. I guess.
    # end

    return all_or_nothing_single(travel_time, td, graph, link_dic)
end

function ta_frank_wolfe(
    td::TA_Data; method=:bfw, max_iter_no=2000, step=:exact, log=:off, tol=1e-3
)
    setup_time = time()

    if log==:on
        println("-------------------------------------")
        println("Network Name: $(td.network_name)")
        println("Method: $method")
        println("Line Search Step: $step")
        println("Maximum Interation Number: $max_iter_no")
        println("Tolerance for AEC: $tol")
        println("Number of processors: ", nprocs())
    end

    # preparing a graph
    graph = create_graph(td.init_node, td.term_node)
    link_dic = sparse(td.init_node, td.term_node, collect(1:td.number_of_links))

    setup_time = time() - setup_time

    if log==:on
        println("Setup time = $setup_time seconds")
    end

    n_links = td.number_of_links

    iteration_time = time()

    # Finding a starting feasible solution
    travel_time = BPR(zeros(n_links), td)
    x0 = all_or_nothing(travel_time, td, graph, link_dic)

    # Initializing variables
    xk = x0
    tauk = 0.0
    yk_FW = x0
    sk_CFW = yk_FW
    Hk_diag = Vector{Float64}(undef, n_links)

    dk_FW = Vector{Float64}(undef, n_links)
    dk_bar = Vector{Float64}(undef, n_links)
    dk_CFW = Vector{Float64}(undef, n_links)
    dk = Vector{Float64}(undef, n_links)

    alphak = 0.0
    Nk = 0.0
    Dk = 0.0

    tauk = 0.0
    is_first_iteration = false
    is_second_iteration = false

    sk_BFW = yk_FW
    sk_BFW_old = yk_FW

    dk_bbar = Vector{Float64}(undef, n_links)
    muk = Vector{Float64}(undef, n_links)
    nuk = Vector{Float64}(undef, n_links)
    beta0 = 0.0
    beta1 = 0.0
    beta2 = 0.0

    for k in 1:max_iter_no
        # Finding yk
        travel_time = BPR(xk, td)
        yk_FW = all_or_nothing(travel_time, td, graph, link_dic)

        # Basic Frank-Wolfe Direction
        dk_FW = yk_FW - xk
        Hk_diag = hessian_diag(xk, td) # Hk_diag is a diagonal vector of matrix Hk

        # Finding a feasible direction
        if method == :fw # Original Frank-Wolfe
            dk = dk_FW
        elseif method == :cfw # Conjugate Direction F-W
            if k==1 || tauk > 0.999999 # If tauk=1, then start the process all over again.
                sk_CFW = yk_FW
                dk_CFW = sk_CFW - xk
            else
                dk_bar = sk_CFW - xk  # sk_CFW from the previous iteration k-1

                Nk = dot(dk_bar, Hk_diag .* dk_FW)
                Dk = dot(dk_bar, Hk_diag .* (dk_FW - dk_bar))

                delta = 0.0001
                if Dk != 0.0 && 0.0 <= Nk/Dk <= 1.0 - delta
                    alphak = Nk/Dk
                elseif Dk != 0.0 && Nk/Dk > 1.0 - delta
                    alphak = 1.0 - delta
                else
                    alphak = 0.0
                end

                # Generating new sk_CFW and dk_CFW
                sk_CFW = alphak .* sk_CFW .+ (1.0 - alphak) .* yk_FW
                dk_CFW = sk_CFW .- xk
            end

            # Feasible Direction to Use for CFW
            dk = dk_CFW
        elseif method == :bfw # Bi-Conjugate Direction F-W
            if tauk > 0.999999
                is_first_iteration = true
                is_second_iteration = true
            end

            if k==1 || is_first_iteration       # First Iteration is like FW
                sk_BFW_old = yk_FW
                dk_BFW = dk_FW
                is_first_iteration = false
            elseif k==2 || is_second_iteration  # Second Iteration is like CFW
                dk_bar = sk_BFW_old - xk # sk_BFW_old from the previous iteration 1

                Nk = dot(dk_bar, Hk_diag .* dk_FW)
                Dk = dot(dk_bar, Hk_diag .* (dk_FW - dk_bar))

                delta = 0.0001
                if Dk != 0.0 && 0.0 <= Nk/Dk <= 1.0 - delta
                    alphak = Nk/Dk
                elseif Dk != 0.0 && Nk/Dk > 1.0 - delta
                    alphak = 1.0 - delta
                else
                    alphak = 0.0
                end

                # Generating new sk_BFW and dk_BFW
                sk_BFW = alphak .* sk_BFW_old .+ (1-alphak) .* yk_FW
                dk_BFW = sk_BFW .- xk

                is_second_iteration = false
            else
                # println("over there $tauk")
                # sk_BFW, tauk is from iteration k-1
                # sk_BFW_old is from iteration k-2

                dk_bar = sk_BFW - xk
                dk_bbar = tauk * sk_BFW - xk + (1.0 - tauk) * sk_BFW_old

                muk =
                    - dot(dk_bbar, Hk_diag .* dk_FW) /
                    dot(dk_bbar, Hk_diag .* (sk_BFW_old - sk_BFW))
                nuk =
                    - dot(dk_bar, Hk_diag .* dk_FW) / dot(dk_bar, Hk_diag .* dk_bar) +
                    muk*tauk/(1-tauk)

                muk = max(0.0, muk)
                nuk = max(0.0, nuk)

                beta0 = 1.0 / (1.0 + muk + nuk)
                beta1 = nuk * beta0
                beta2 = muk * beta0

                sk_BFW_new = beta0 * yk_FW + beta1 * sk_BFW + beta2 * sk_BFW_old
                dk_BFW = sk_BFW_new - xk

                sk_BFW_old = sk_BFW
                sk_BFW = sk_BFW_new
            end

            # Feasible Direction to Use for BFW
            dk = dk_BFW
        else
            error(
                "The type of Frank-Wolfe method is specified incorrectly. Use :fw, :cfw, or :bfw.",
            )
        end
        # dk is now identified.

        if step == :exact
            # Line Search from xk in the direction dk
            optk = optimize(tau -> objective(xk+tau*dk, td), 0.0, 1.0, GoldenSection())
            tauk = optk.minimizer
        elseif step == :newton
            # Newton step
            tauk = - dot(gradient(xk, td), dk) / dot(dk, Hk_diag .* dk)
            tauk = max(0.0, min(1.0, tauk))
        end

        # Average Excess Cost
        average_excess_cost =
            (xk' * travel_time - yk_FW' * travel_time) / sum(td.travel_demand)
        if log==:on
            @printf(
                "k=%4d, tauk=%15.10f, objective=%15f, aec=%15.10f\n",
                k,
                tauk,
                objective(xk, td),
                average_excess_cost
            )
        end

        # rel_gap = ( objective(xk) - best_objective ) / best_objective

        # Convergence Test
        if average_excess_cost < tol
            # if rel_gap < tol
            break
        end

        # Update x
        new_x = xk + tauk * dk
        xk = new_x

        @assert minimum(xk) >= 0
    end

    iteration_time = time() - iteration_time

    if log==:on
        println("Iteration time = $iteration_time seconds")
    end

    return xk, travel_time, objective(xk, td)
end

#
