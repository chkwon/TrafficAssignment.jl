# Tutorial

!!! warning
    Page in construction.

```@example tuto
using TrafficAssignment
using PrettyTables  # for table display
using CairoMakie, Tyler  # for plotting
```

## Instances

The package gives you access to the following instances:

```@example tuto
pretty_table(summarize_instances())
```

To download and parse one, just specify its name inside the [`TrafficAssignmentProblem`](@ref) constructor:

```@example tuto
problem = TrafficAssignmentProblem("SiouxFalls")
```

## Visualization

You can visualize instances as follows:

```@example tuto
plot_network(problem)
```

## Solution

You can solve instances as follows:

```@example tuto
flow = solve_frank_wolfe(problem; verbose=false, max_iteration=1000)
```
