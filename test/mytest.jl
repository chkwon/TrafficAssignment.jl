using LightGraphs
include("../src/load_network.jl")
include("../src/misc.jl")
include("../src/frank_wolfe.jl")


ta_data = load_ta_network("Barcelona")
@time link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, step=:newton, log=:on, tol=1e-3, max_iter_no=1)

1.0
