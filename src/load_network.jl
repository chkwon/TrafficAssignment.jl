# Sioux Falls network data
# http://www.bgu.ac.il/~bargera/tntp/

#Link travel time = free flow time * ( 1 + b * (flow/capacity)^Power ).
#Link generalized cost = Link travel time + toll_factor * toll + distance_factor * distance

# Traffic Assignment Data structure
"""
$(TYPEDEF)

# Fields

$(TYPEDFIELDS)
"""
@kwdef struct TrafficAssignmentProblem{
    C<:Union{Nothing,Vector{Float64}},F<:Union{Nothing,SparseMatrixCSC{Float64,Int}}
}
    instance_name::String

    # network table
    number_of_zones::Int
    number_of_nodes::Int
    first_thru_node::Int
    number_of_links::Int

    init_node::Vector{Int}
    term_node::Vector{Int}
    capacity::Vector{Float64}
    link_length::Vector{Float64}
    free_flow_time::Vector{Float64}
    b::Vector{Float64}
    power::Vector{Float64}
    speed_limit::Vector{Float64}
    toll::Vector{Float64}
    link_type::Vector{Int}

    # trips table
    total_od_flow::Float64
    travel_demand::Matrix{Float64}
    od_pairs::Vector{Tuple{Int,Int}}

    # node table
    X::C
    Y::C

    # flow table
    optimal_flow_volume::F
    optimal_flow_cost::F

    # cost parameters
    toll_factor::Float64
    distance_factor::Float64
end

function Base.show(io::IO, problem::TrafficAssignmentProblem)
    (; instance_name, number_of_nodes, number_of_links) = problem
    return print(
        io,
        "Traffic assignment problem on the $instance_name network with $number_of_nodes nodes and $number_of_links links",
    )
end

search_sc(s, c) = something(findfirst(isequal(c), s), 0)

"""
$(SIGNATURES)

Return a named tuple `(; flow_file, net_file, node_file, trips_file)` containing the absolute paths to the 4 data tables of an instance.
"""
function instance_files(instance_name::AbstractString)
    instance_dir = datapath(instance_name)
    @assert ispath(instance_dir)

    flow_file = net_file = node_file = trips_file = nothing
    for f in readdir(instance_dir; join=true)
        if occursin("_flow", lowercase(f)) && occursin(".tntp", lowercase(f))
            flow_file = f
        elseif occursin("_net", lowercase(f)) && occursin(".tntp", lowercase(f))
            net_file = f
        elseif occursin("_node", lowercase(f)) && occursin(".tntp", lowercase(f))
            node_file = f
        elseif occursin("_trips", lowercase(f)) && occursin(".tntp", lowercase(f))
            trips_file = f
        end
    end

    @assert !isnothing(net_file)
    @assert !isnothing(trips_file)

    return (; flow_file, net_file, node_file, trips_file)
end

"""
$(SIGNATURES)

User-friendly constructor for [`TrafficAssignmentProblem`](@ref).

The provided `instance_name` must be one of the subfolders in [https://github.com/bstabler/TransportationNetworks](https://github.com/bstabler/TransportationNetworks).

When you run this function for the first time, the DataDeps package will ask you to confirm download.
If you want to skip this check, for instance during CI, set the environment variable `ENV["DATADEPS_ALWAYS_ACCEPT"] = true`.
"""
function TrafficAssignmentProblem(
    instance_name::AbstractString,
    files::NamedTuple=instance_files(instance_name);
    toll_factor::Real=0.0,
    distance_factor::Real=0.0,
)
    (; net_file, trips_file, node_file, flow_file) = files
    @assert ispath(net_file)
    @assert ispath(trips_file)

    # network table

    number_of_zones = 0
    number_of_links = 0
    number_of_nodes = 0
    first_thru_node = 0

    n = open(net_file, "r")

    while (line = readline(n)) != ""
        if occursin("<NUMBER OF ZONES>", line)
            number_of_zones = parse(Int, line[(search_sc(line, '>') + 1):end])
        elseif occursin("<NUMBER OF NODES>", line)
            number_of_nodes = parse(Int, line[(search_sc(line, '>') + 1):end])
        elseif occursin("<FIRST THRU NODE>", line)
            first_thru_node = parse(Int, line[(search_sc(line, '>') + 1):end])
        elseif occursin("<NUMBER OF LINKS>", line)
            number_of_links = parse(Int, line[(search_sc(line, '>') + 1):end])
        elseif occursin("<END OF METADATA>", line)
            break
        end
    end

    @assert number_of_links > 0

    init_node = zeros(Int, number_of_links)
    term_node = zeros(Int, number_of_links)
    capacity = zeros(Float64, number_of_links)
    link_length = zeros(Float64, number_of_links)
    free_flow_time = zeros(Float64, number_of_links)
    b = zeros(Float64, number_of_links)
    power = zeros(Float64, number_of_links)
    speed_limit = zeros(Float64, number_of_links)
    toll = zeros(Float64, number_of_links)
    link_type = zeros(Int, number_of_links)

    idx = 1
    while !eof(n)
        line = readline(n)
        if occursin("~", line) || line == ""
            continue
        end

        if occursin(";", line)
            line = strip(line, [' ', '\n', ';'])
            line = replace(line, ";" => "")

            numbers = split(line)
            init_node[idx] = parse(Int, numbers[1])
            term_node[idx] = parse(Int, numbers[2])
            capacity[idx] = parse(Float64, numbers[3])
            link_length[idx] = parse(Float64, numbers[4])
            free_flow_time[idx] = parse(Float64, numbers[5])
            b[idx] = parse(Float64, numbers[6])
            power[idx] = parse(Float64, numbers[7])
            speed_limit[idx] = parse(Float64, numbers[8])
            toll[idx] = parse(Float64, numbers[9])
            link_type[idx] = Int(round(parse(Float64, numbers[10])))

            idx = idx + 1
        end
    end

    # trips table

    number_of_zones_trip = 0
    total_od_flow = 0

    f = open(trips_file, "r")

    while (line = readline(f)) != ""
        if occursin("<NUMBER OF ZONES>", line)
            number_of_zones_trip = parse(Int, line[(search_sc(line, '>') + 1):end])
        elseif occursin("<TOTAL OD FLOW>", line)
            total_od_flow = parse(Float64, line[(search_sc(line, '>') + 1):end])
        elseif occursin("<END OF METADATA>", line)
            break
        end
    end

    @assert number_of_zones_trip == number_of_zones # Check if number_of_zone is same in both txt files
    @assert total_od_flow > 0

    travel_demand = zeros(Float64, number_of_zones, number_of_zones)
    od_pairs = Tuple{Int,Int}[]

    origin = -1

    while !eof(f)
        line = readline(f)

        if line == ""
            origin = -1
            continue
        elseif occursin("Origin", line)
            origin = parse(Int, split(line)[2])
        elseif occursin(";", line)
            pairs = split(line, ";")
            for i in 1:size(pairs)[1]
                if occursin(":", pairs[i])
                    pair = split(pairs[i], ":")
                    destination = parse(Int, strip(pair[1]))
                    od_flow = parse(Float64, strip(pair[2]))

                    # println("origin=$origin, destination=$destination, flow=$od_flow")

                    travel_demand[origin, destination] = od_flow
                    push!(od_pairs, (origin, destination))
                end
            end
        end
    end

    # node table

    if !isnothing(node_file)
        X = fill(NaN, number_of_nodes)
        Y = fill(NaN, number_of_nodes)
        coord_lines = readlines(node_file)
        if startswith(lowercase(coord_lines[1]), "node")
            coord_lines = @view(coord_lines[2:end])
        end
        coord_lines_split = split.(coord_lines, Ref(r"[\t ]+"))
        X = parse.(Float64, getindex.(coord_lines_split, 2))
        Y = parse.(Float64, getindex.(coord_lines_split, 3))
    else
        X = nothing
        Y = nothing
    end

    if !isnothing(flow_file) && instance_name != "chicago-regional"
        optimal_flow = DataFrame(CSV.File(flow_file))
        optimal_flow_volume = sparse(
            optimal_flow[!, "From "],
            optimal_flow[!, "To "],
            optimal_flow[!, "Volume "],
            number_of_nodes,
            number_of_nodes,
        )
        optimal_flow_cost = sparse(
            optimal_flow[!, "From "],
            optimal_flow[!, "To "],
            optimal_flow[!, "Cost "],
            number_of_nodes,
            number_of_nodes,
        )
    else
        optimal_flow_volume = nothing
        optimal_flow_cost = nothing
    end

    return TrafficAssignmentProblem(;
        instance_name,
        number_of_zones,
        number_of_nodes,
        first_thru_node,
        number_of_links,
        init_node,
        term_node,
        capacity,
        link_length,
        free_flow_time,
        b,
        power,
        speed_limit,
        toll,
        link_type,
        total_od_flow,
        travel_demand,
        od_pairs,
        X,
        Y,
        optimal_flow_volume,
        optimal_flow_cost,
        toll_factor,
        distance_factor,
    )
end

"""
$(SIGNATURES)

Return a list of available instance names.
"""
function list_instances()
    data_dir = datapath()
    names = String[]
    for potential_name in readdir(data_dir)
        isdir(joinpath(data_dir, potential_name)) || continue
        for instance_file in readdir(joinpath(data_dir, potential_name))
            if endswith(instance_file, ".tntp")
                push!(names, potential_name)
                break
            end
        end
    end
    return names
end

"""
$(SIGNATURES)

Return a `DataFrame` summarizing the dimensions of all available instances.
"""
function summarize_instances()
    df = DataFrame(; instance=String[], valid=Bool[], zones=Int[], nodes=Int[], links=Int[])
    for instance in list_instances()
        valid = false
        number_of_zones, number_of_nodes, number_of_links = (-1, -1, -1)
        try
            problem = TrafficAssignmentProblem(instance)
            valid = true
            (; number_of_zones, number_of_nodes, number_of_links) = problem
        catch exception
            @warn "Loading $instance failed" exception
            # nothing
        end
        push!(
            df,
            (;
                instance,
                valid,
                zones=number_of_zones,
                nodes=number_of_nodes,
                links=number_of_links,
            ),
        )
    end
    return df
end
