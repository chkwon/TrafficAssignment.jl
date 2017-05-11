using TrafficAssignment
using Base.Test

function test_tntp()
  data_dir = download_tntp()

  # Test
  for d in readdir(data_dir)
    if isdir(joinpath(data_dir, d))
      try
        read_ta_network(d)
        info("Network '$d' is OK.")
      catch e
        warn("Network '$d' is not usable.")
      end
    end
  end
end

test_tntp()

data_time = time()
ta_data = load_ta_network("SiouxFalls")

println("Data Loading Completed, time:", time() - data_time, " seconds")

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:bfw, step=:exact, log=:on, tol=1e-3, max_iter_no=5)

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, step=:newton, log=:on, tol=1e-3, max_iter_no=5)

link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:fw, step=:exact, log=:on, tol=1e-3, max_iter_no=5)
@assert abs( objective - 4.963799502172654e6 ) < 1e6
