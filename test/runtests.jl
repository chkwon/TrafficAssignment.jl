using TrafficAssignment
using Base.Test

# write your own tests here

ta_data = load_ta_network("Sioux Falls")
# ta_data = load_ta_network("Anaheim")
ta_data = load_ta_network("Barcelona")
# ta_data = load_ta_network("Chicago Sketch")
# ta_data = load_ta_network("Winnipeg")


link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, log="on", tol=1e-3, max_iter_no=20)
