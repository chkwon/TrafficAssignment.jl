# TrafficAssignment.jl

[![Build Status](https://github.com/chkwon/TrafficAssignment.jl/workflows/CI/badge.svg?branch=master)](https://github.com/chkwon/TrafficAssignment.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/chkwon/TrafficAssignment.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/chkwon/TrafficAssignment.jl)


This package for [the Julia Language](http://www.julialang.org) does basically two tasks: (1) loading a network data and (2) finding a user equilibrium traffic pattern. See [Traffic Assignment](https://en.wikipedia.org/wiki/Route_assignment).

# Install


```julia
julia> Pkg.add("TrafficAssignment")
```

This will install [LightGraphs.jl](https://github.com/JuliaGraphs/LightGraphs.jl) and [Optim.jl](https://github.com/JuliaOpt/Optim.jl), if you don't have them already.

To check if works
```julia
julia> Pkg.test("TrafficAssignment")
```

# load_ta_network

This function loads a network data available in [this TNTP github repository](https://github.com/bstabler/TransportationNetworks). The network name must match with the directory name in the TNTP repository.

Example:
```julia
using TrafficAssignment
ta_data = load_ta_network("SiouxFalls")
# ta_data = load_ta_network("Anaheim")
# ta_data = load_ta_network("Barcelona")
# ta_data = load_ta_network("Winnipeg")
```

The return value is of the TA_Data type, which is defined as
```julia
mutable struct TA_Data
    network_name::String

    number_of_zones::Int
    number_of_nodes::Int
    first_thru_node::Int
    number_of_links::Int

    init_node::Array{Int,1}
    term_node::Array{Int,1}
    capacity::Array{Float64,1}
    link_length::Array{Float64,1}
    free_flow_time::Array{Float64,1}
    b::Array{Float64,1}
    power::Array{Float64,1}
    speed_limit::Array{Float64,1}
    toll::Array{Float64,1}
    link_type::Array{Int64,1}

    total_od_flow::Float64

    travel_demand::Array{Float64,2}
    od_pairs::Array{Tuple{Int64,Int64},1}

    toll_factor::Float64
    distance_factor::Float64

    best_objective::Float64
end
```

# ta_frank_wolfe

This function implements methods to find traffic equilibrium flows: currently, Frank-Wolfe (FW) method, Conjugate FW (CFW) method, and Bi-conjugate FW (BFW) method.

References:
- [Mitradjieva, M., & Lindberg, P. O. (2013). The Stiff Is Moving-Conjugate Direction Frank-Wolfe Methods with Applications to Traffic Assignment. *Transportation Science*, 47(2), 280-293.](http://pubsonline.informs.org/doi/abs/10.1287/trsc.1120.0409)

Example:
```julia
link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, log="off", tol=1e-2)
```

Available optional arguments:
* method=:fw / :cfw / :bfw (default=:bfw)
* step="exact" / "newton" : exact line search using golden section / a simple Newton-type step (default=:exact)
* log=:on / :off : displays information from each iteration or not (default=:off)
* max_iter_no=*integer value* : maximum number of iterations (default=2000)
* tol=*numeric value* : tolerance for the Average Excess Cost (AEC) (default=1e-3)

For example, one may do:
```julia
ta_data = load_ta_network("SiouxFalls")
link_flow, link_travel_time, objective =
ta_frank_wolfe(ta_data, method=:cfw, max_iter_no=50000, step=:newton, log=:on, tol=1e-5)
```

The total system travel time can be simply computed as
```julia
using LinearAlgebra
system_travel_time = dot(link_travel_time, link_flow)
```


# Contributor
This package is written and maintained by [Changhyun Kwon](http://www.chkwon.net).
