using TrafficAssignment
using Base.Test

# write your own tests here

data_time = time()
ta_data = load_ta_network("Sioux Falls")
# ta_data = load_ta_network("Anaheim")
# ta_data = load_ta_network("Barcelona")
# ta_data = load_ta_network("Chicago Sketch")
# ta_data = load_ta_network("Winnipeg")
println("Data Loading Completed, time:", time() - data_time, " seconds")

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:bfw, log=:on, tol=1e-3, max_iter_no=5)

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, log=:on, tol=1e-3, max_iter_no=5)

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:fw, log=:on, tol=1e-3, max_iter_no=5)
