# TrafficAssignment.jl

[![Build Status](https://travis-ci.org/chkwon/TrafficAssignment.jl.svg?branch=master)](https://travis-ci.org/chkwon/TrafficAssignment.jl)

This package does basically two tasks: (1) loading a network data and (2) finding a user equilibrium traffic pattern.

# Install

This package requires [Graphs.jl](https://github.com/JuliaLang/Graphs.jl) and [Optim.jl](https://github.com/JuliaOpt/Optim.jl).

```julia
julia> Pkg.add("Graphs")
julia> Pkg.add("Optim")
julia> Pkg.clone("https://github.com/chkwon/TrafficAssignment.jl.git")
```

# load_ta_network

This function loads a network data available in Hillel Bar-Ger's [Transportation Network Test Problems](http://www.bgu.ac.il/~bargera/tntp/).

Example:
```julia
ta_data = load_ta_network("Sioux Falls")
# ta_data = load_ta_network("Anaheim")
# ta_data = load_ta_network("Barcelona")
# ta_data = load_ta_network("Chicago Sketch")
# ta_data = load_ta_network("Winnipeg")
```

The return value is of the TA_Data type, which is defined as
```julia
type TA_Data
    network_name::String

    number_of_zones::Int64
    number_of_nodes::Int64
    first_thru_node::Int64
    number_of_links::Int64

    start_node::Array
    end_node::Array
    capacity::Array
    link_length::Array
    free_flow_time::Array
    B::Array
    power::Array
    speed_limit::Array
    toll::Array
    link_type::Array

    total_od_flow::Float64

    travel_demand::Array
    od_pairs::Array

    toll_factor::Float64
    distance_factor::Float64

    best_objective::Float64
end
```

# ta_frank_wolfe

This function implements methods to find traffic equilibrium flows: currently, Frank-Wolfe (FW) method, Conjugate FW (CFW) method, and Bi-conjugate FW (BFW) method.

References:
- [Mitradjieva, M., & Lindberg, P. O. (2013). The Stiff Is Moving-Conjugate Direction Frank-Wolfe Methods with Applications to Traffic Assignment*. Transportation Science, 47(2), 280-293.](http://pubsonline.informs.org/doi/abs/10.1287/trsc.1120.0409)

Example:
```julia
link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, log="off", tol=1e-2)
```

Available optional arguments:
* method="FW" / "CFW" / "BFW" (default: BFW)
* step="exact" / "newton" : exact line search using golden section / a simple Newton-type step (default: exact)
* log="on" / "off" : displays information from each iteration or not (default: off)
* max_iter_no=*integer value* : maximum number of iterations (default: 2000)
* tol="numeric value" : tolerance for the Average Excess Cost (AEC) (default: 1e-3)

For example, one may do:
```julia
ta_data = load_ta_network("Sioux Falls")
link_flow, link_travel_time, objective = ta_frank_wolfe(ta_data, method="CFW", max_iter_no=50000, step="newton", log="on", tol=1e-5)
```



# Contributor
This package was written and maintained by [Changhyun Kwon](http://www.chkwon.net).
