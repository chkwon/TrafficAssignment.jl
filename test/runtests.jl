using TrafficAssignment
using Base.Test


ta_data = load_ta_network("Anaheim")
ta_data = load_ta_network("Barcelona")
ta_data = load_ta_network("Chicago Sketch")
ta_data = load_ta_network("Winnipeg")




data_time = time()
ta_data = load_ta_network("Sioux Falls")

println("Data Loading Completed, time:", time() - data_time, " seconds")

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:bfw, step=:exact, log=:on, tol=1e-3, max_iter_no=5)

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, step=:newton, log=:on, tol=1e-3, max_iter_no=5)

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:fw, step=:exact, log=:on, tol=1e-3, max_iter_no=5)
@assert abs( objective - 4.963799502172654e6 ) < 1e6
