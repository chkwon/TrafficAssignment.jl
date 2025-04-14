"""
$(SIGNATURES)

Return a named tuple `(; flow_file, net_file, node_file, trips_file)` containing the absolute paths to the 4 data tables of an instance.
"""
function instance_files(instance_name::AbstractString)
    instance_dir = datapath(instance_name)
    @assert ispath(instance_dir)

    flow_file = net_file = node_file = trips_file = nothing
    for f in readdir(instance_dir; join=true)
        if occursin("_flow", lowercase(f)) && endswith(lowercase(f), ".tntp")
            flow_file = f
        elseif occursin("_net", lowercase(f)) && endswith(lowercase(f), ".tntp")
            net_file = f
        elseif occursin("_node", lowercase(f)) && endswith(lowercase(f), ".tntp")
            node_file = f
        elseif occursin("_trips", lowercase(f)) && endswith(lowercase(f), ".tntp")
            trips_file = f
        end
    end

    if instance_name == "Munich"
        # https://github.com/bstabler/TransportationNetworks/issues/59
        net_file, trips_file = trips_file, net_file
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
    instance_name::AbstractString; toll_factor::Real=0.0, distance_factor::Real=0.0
)
    (; net_file, trips_file, node_file, flow_file) = instance_files(instance_name)
    @assert ispath(net_file)
    @assert ispath(trips_file)

    # network table

    number_of_zones = 0
    number_of_links = 0
    number_of_nodes = 0
    first_thru_node = 0

    any_nb_of_spaces = r"[ \t]+"

    header_row = 0
    net_lines = readlines(net_file)
    for (k, line) in enumerate(net_lines)
        if startswith(line, "<NUMBER OF ZONES>")
            number_of_zones = parse(Int, split(line, any_nb_of_spaces)[4])
        elseif startswith(line, "<NUMBER OF NODES>")
            number_of_nodes = parse(Int, split(line, any_nb_of_spaces)[4])
        elseif startswith(line, "<NUMBER OF LINKS>")
            number_of_links = parse(Int, split(line, any_nb_of_spaces)[4])
        elseif startswith(line, "<FIRST THRU NODE>")
            first_thru_node = parse(Int, split(line, any_nb_of_spaces)[4])
        elseif startswith(line, "~")
            header_row = k
            break
        end
    end
    if number_of_zones == 0
        number_of_zones = number_of_nodes
    end
    net_col_names = string.(split(net_lines[header_row], any_nb_of_spaces))
    if first(net_col_names) == "~" &&
        !startswith(net_lines[header_row + 1], any_nb_of_spaces)
        # first column is not empty
        deleteat!(net_col_names, 1)
    end
    net_df = DataFrame(
        CSV.File(
            net_file;
            delim='\t',
            skipto=header_row + 1,
            header=net_col_names,
            maxwarnings=1,
            silencewarnings=true,
            drop=(i, name) -> i > length(net_col_names),
        ),
    )
    @assert size(net_df, 1) == number_of_links

    n, m = number_of_nodes, number_of_links
    I = net_df[!, :init_node]
    J = net_df[!, :term_node]

    capacity = sparse(I, J, float.(net_df[!, :capacity]), n, n)
    link_length = sparse(I, J, float.(net_df[!, :length]), n, n)
    free_flow_time = sparse(I, J, float.(net_df[!, :free_flow_time]), n, n)
    speed_limit = sparse(I, J, float.(net_df[!, :speed]), n, n)
    if ==(extrema(net_df[!, :b])...)
        b = float(first(net_df[!, :b]))  # single b value
    else
        b = sparse(I, J, float.(net_df[!, :b]), n, n)
    end
    if ==(extrema(net_df[!, :power])...)
        power = float(first(net_df[!, :power]))  # single power value
    else
        power = sparse(I, J, float.(net_df[!, :power]), n, n)
    end
    if "toll" in names(net_df)
        toll = sparse(I, J, float.(net_df[!, :toll]), n, n)
    else
        toll = missing
    end
    if "link_type" in names(net_df)
        link_type_nzval = if eltype(net_df[!, :link_type]) <: AbstractString
            # in some instances, the semicolon is stuck at the end
            parse.(Int, strip.(net_df[!, :link_type], ';'))
        else
            net_df[!, :link_type]
        end
        link_type = sparse(I, J, link_type_nzval, n, n)
    else
        link_type = missing
    end

    # trips table
    number_of_zones_trip = 0
    total_od_flow = 0

    travel_demand = Dict{Tuple{Int,Int},Float64}()

    trips_lines = readlines(trips_file)
    origin = -1
    for line in trips_lines
        if startswith(line, "<NUMBER OF ZONES>")
            number_of_zones_trip = parse(Int, split(line, any_nb_of_spaces)[4])
        elseif startswith(line, "<TOTAL OD FLOW>")
            total_od_flow = parse(Float64, split(line, any_nb_of_spaces)[4])
        elseif line == ""
            origin = -1
        elseif occursin("Origin", line)
            origin = parse(Int, split(line)[2])
        elseif occursin(";", line)
            pairs = split(line, ";")
            for i in 1:size(pairs)[1]
                if occursin(":", pairs[i])
                    pair = split(pairs[i], ":")
                    destination = parse(Int, strip(pair[1]))
                    od_flow = parse(Float64, strip(pair[2]))
                    travel_demand[origin, destination] = od_flow
                end
            end
        end
    end

    @assert number_of_zones_trip == number_of_zones # Check if number_of_zone is same in both txt files
    @assert total_od_flow > 0

    # node table

    if !isnothing(node_file)
        coord_lines = readlines(node_file)
        if startswith(lowercase(coord_lines[1]), "node")
            coord_lines = @view(coord_lines[2:end])
        end
        coord_lines_split = split.(coord_lines, Ref(r"[\t ]+"))
        inds = parse.(Int, getindex.(coord_lines_split, 1))
        @assert inds == 1:number_of_nodes
        x = parse.(Float64, getindex.(coord_lines_split, 2))
        y = parse.(Float64, getindex.(coord_lines_split, 3))
        source_crs = if occursin("Birmingham", instance_name)
            "EPSG:27700"  # right
        elseif occursin("chicago", lowercase(instance_name))
            "EPSG:26771"  # slightly off
        elseif instance_name in ("GoldCoast", "SiouxFalls", "Sydney")
            "WGS84"
        else
            nothing
        end
        if source_crs !== nothing
            trans = Proj.Transformation(source_crs, "WGS84"; always_xy=true)
            longlat = trans.(collect(zip(x, y)))
            node_x = first.(longlat)
            node_y = last.(longlat)
            valid_longitude_latitude = true
        else
            node_x = x
            node_y = y
            valid_longitude_latitude = false
        end
    else
        node_x = missing
        node_y = missing
        valid_longitude_latitude = false
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
        node_x,
        node_y,
        valid_longitude_latitude,
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
        yield()
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
