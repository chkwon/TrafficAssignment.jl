using TrafficAssignment, LinearAlgebra
using Test

include("test_functions.jl")


# test_tntp()

# summarize_ta_data()

data_time = time()
ta_data = load_ta_network("SiouxFalls")

println("Data Loading Completed, time:", time() - data_time, " seconds")

# link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:bfw, step=:exact, log=:on, tol=1e-3, max_iter_no=5)
#
# link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, step=:newton, log=:on, tol=1e-3, max_iter_no=5)
#
# link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:fw, step=:exact, log=:on, tol=1e-3, max_iter_no=5)
# @assert abs( objective - 4.963799502172654e6 ) < 1e6

@time link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, step=:newton, log=:on, tol=1e-5, max_iter_no=5000)

@show dot(link_flow, link_travel_time)

@time link_flow_so, link_travel_time_so, objective_so = ta_system_optimum(ta_data)

@show objective_so, dot(link_flow_so, link_travel_time_so)
