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
@kwdef struct TrafficAssignmentProblem
    instance_name::String

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

    total_od_flow::Float64

    travel_demand::Matrix{Float64}
    od_pairs::Vector{Tuple{Int,Int}}

    toll_factor::Float64
    distance_factor::Float64

    best_objective::Float64
end

function DataFrames.DataFrame(td::TrafficAssignmentProblem)
    return DataFrame(;
        init_node=td.init_node,
        term_node=td.term_node,
        capacity=td.capacity,
        link_length=td.link_length,
        free_flow_time=td.free_flow_time,
        b=td.b,
        power=td.power,
        speed_limit=td.speed_limit,
        toll=td.toll,
        link_type=td.link_type,
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
"""
function TrafficAssignmentProblem(
    instance_name::AbstractString,
    files::NamedTuple=instance_files(instance_name);
    best_objective::Real=-1.0,
    toll_factor::Real=0.0,
    distance_factor::Real=0.0,
)
    (; net_file, trips_file) = files
    @assert ispath(net_file)
    @assert ispath(trips_file)

    ##################################################
    # Network Data
    ##################################################

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

    ##################################################
    # Trip Table
    ##################################################

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
        toll_factor,
        distance_factor,
        best_objective,
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
        catch e
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
