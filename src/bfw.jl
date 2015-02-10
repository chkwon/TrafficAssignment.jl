





using Graphs, Optim

tic()

include("SiouxFalls.jl")

include("misc.jl")


# Initialization
graph = create_graph(start_node, end_node)

# Finding a starting feasible solution
travel_time = BPR(zeros(number_of_links))
x0 = all_or_nothing(travel_time)

# Frank-Wolfe Iteration
xk = x0
lambdak = 0
yk = x0
dk = yk-xk

for k=1:1869
    # Finding yk
    travel_time = BPR(xk)
    yk = all_or_nothing(travel_time)

    # Feasible Direction
    dk = yk - xk

    # Line Search from xk in the direction dk
    optk = optimize(fk, 0.0, 1.0, method = :golden_section)
    lambdak = optk.minimum

    new_x = xk + lambdak*dk

    # println("k=$k,\t lambda=$lambdak,\t objective=$(objective(xk))")

    error = norm(new_x - xk) / norm(xk)
    println("k=$k,\t error=$error")

    if error < 1e-3
        break
    end

    # Update x
    xk = new_x

end


println( objective(xk) )

# println([xk travel_time])


toc()





#
