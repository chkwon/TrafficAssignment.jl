# TrafficAssignment.jl

[![Build Status](https://github.com/gdalle/TrafficAssignment.jl/actions/workflows/Test.yml/badge.svg?branch=master)](https://github.com/gdalle/TrafficAssignment.jl/actions/workflows/Test.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/gdalle/TrafficAssignment.jl/branch/master/graph/badge.svg)](https://app.codecov.io/gh/gdalle/TrafficAssignment.jl)
[![Dev Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://gdalle.github.io/TrafficAssignment.jl/dev/)

This is a Julia package for studying [traffic assignment](https://en.wikipedia.org/wiki/Route_assignment) on road networks.

## Getting started

To install the latest development version, run this in your Julia Pkg REPL:

```julia
pkg> add https://github.com/gdalle/TrafficAssignment.jl
```

You can easily load networks from the [`TransportationNetworks` repository](https://github.com/bstabler/TransportationNetworks):

```jldoctest readme
julia> using TrafficAssignment

julia> problem = TrafficAssignmentProblem("SiouxFalls")
Traffic assignment problem on the SiouxFalls network with 24 nodes and 76 links
```

And then you can solve the equilibrium problem and compute the total system travel time:

```jldoctest readme
julia> flow = solve_frank_wolfe(problem; max_iteration=1000, verbose=false)
24×24 SparseArrays.SparseMatrixCSC{Float64, Int64} with 76 stored entries:
⎡⠎⡡⡐⠀⠀⡠⠀⠀⠀⠀⠀⠀⎤
⎢⠐⠈⢊⡰⡁⠀⠀⢀⠠⠀⠀⠀⎥
⎢⠀⡠⠁⠈⠪⡢⡠⠒⠂⠀⠀⠀⎥
⎢⠀⠀⠀⢀⢠⠊⠠⠂⣀⠄⠠⠊⎥
⎢⠀⠀⠀⠂⠈⠀⠀⠜⢄⡱⣀⠀⎥
⎣⠀⠀⠀⠀⠀⠀⡠⠂⠀⠘⡪⡪⎦

julia> round(social_cost(problem, flow), sigdigits=4)
7.481e6
```

## Credits

This package was originally written and maintained by [Changhyun Kwon](http://www.chkwon.net).
