using Graphs, Optim



include("load_network.jl")
include("fw.jl")

ta_data = load_ta_network("Sioux Falls")
# ta_data = load_ta_network("Anaheim")
# ta_data = load_ta_network("Barcelona")
# ta_data = load_ta_network("Chicago Sketch")
# ta_data = load_ta_network("Winnipeg")


# x, travel_time, objective = ta_frank_wolfe(ta_data, "FW")

tic()
link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method="BFW",
                        max_iter_no=50000, step="exact", log="on", tol=1e-4)
toc()
