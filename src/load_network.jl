# Sioux Falls network data
# http://www.bgu.ac.il/~bargera/tntp/

#Link travel time = free flow time * ( 1 + B * (flow/capacity)^Power ).
#Link generalized cost = Link travel time + toll_factor * toll + distance_factor * distance

# Traffic Assignment Data structure
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

function load_ta_network(network_name="Sioux Falls")

    toll_factor = 0
    distance_factor = 0

    if network_name == "Sioux Falls"
        network_data_file = "SiouxFalls_net.txt"
        trip_table_file = "SiouxFalls_trips.txt"
        best_objective = 4.231335287107440e6 #42.31335287107440
    elseif network_name == "Barcelona"
        network_data_file = "Barcelona_net.txt"
        trip_table_file = "Barcelona_trips.txt"
        best_objective = 1
    elseif network_name =="Chicago Sketch"
        network_data_file = "ChicagoSketch_net.txt"
        trip_table_file = "ChicagoSketch_trips.txt"
        best_objective = 1
        toll_factor = 0.02
        distance_factor = 0.04
    elseif network_name == "Anaheim"
        network_data_file = "Anaheim_net.txt"
        trip_table_file = "Anaheim_trips.txt"
        best_objective = 1
    elseif network_name == "Winnipeg"
        network_data_file = "Winnipeg_net.txt"
        trip_table_file = "Winnipeg_trips.txt"
        best_objective = 1
    end

    network_data_file = joinpath(Pkg.dir("TrafficAssignment"), "data", network_data_file)
    trip_table_file = joinpath(Pkg.dir("TrafficAssignment"), "data", trip_table_file)




    ##################################################
    # Network Data
    ##################################################


    number_of_zones = 0
    number_of_links = 0
    number_of_nodes = 0
    first_thru_node = 0

    n = open(network_data_file, "r")

    while (line=readline(n)) != ""
        if contains(line, "<NUMBER OF ZONES>")
            number_of_zones = parseint( line[ search(line, '>')+1 : end-1 ] )
        elseif contains(line, "<NUMBER OF NODES>")
            number_of_nodes = parseint( line[ search(line, '>')+1 : end-1 ] )
        elseif contains(line, "<FIRST THRU NODE>")
            first_thru_node = parseint( line[ search(line, '>')+1 : end-1 ] )
        elseif contains(line, "<NUMBER OF LINKS>")
            number_of_links = parseint( line[ search(line, '>')+1 : end-1 ] )
        elseif contains(line, "<END OF METADATA>")
            break
        end
    end

    @assert number_of_links > 0

    start_node = Array(Int, number_of_links)
    end_node = Array(Int, number_of_links)
    capacity = zeros(number_of_links)
    link_length = zeros(number_of_links)
    free_flow_time = zeros(number_of_links)
    B = zeros(number_of_links)
    power = zeros(number_of_links)
    speed_limit = zeros(number_of_links)
    toll = zeros(number_of_links)
    link_type = Array(Int, number_of_links)

    idx = 1
    while (line=readline(n)) != ""
        if contains(line, "~")
            continue
        end

        if contains(line, ";")
            line = strip(line, '\n')
            line = strip(line, ';')

            numbers = split(line)

            start_node[idx] = parseint(numbers[1])
            end_node[idx] = parseint(numbers[2])
            capacity[idx] = parsefloat(numbers[3])
            link_length[idx] = parsefloat(numbers[4])
            free_flow_time[idx] = parsefloat(numbers[5])
            B[idx] = parsefloat(numbers[6])
            power[idx] = parsefloat(numbers[7])
            speed_limit[idx] = parsefloat(numbers[8])
            toll[idx] = parsefloat(numbers[9])
            link_type[idx] = parseint(numbers[10])

            idx = idx + 1
        end
    end

    ##################################################
    # Trip Table
    ##################################################

    number_of_zones_trip = 0
    total_od_flow = 0

    f = open(trip_table_file, "r")

    while (line=readline(f)) != ""
        if contains(line, "<NUMBER OF ZONES>")
            number_of_zones_trip = parseint( line[ search(line, '>')+1 : end-1 ] )
        elseif contains(line, "<TOTAL OD FLOW>")
            total_od_flow = parsefloat( line[ search(line, '>')+1 : end-1 ] )
        elseif contains(line, "<END OF METADATA>")
            break
        end
    end

    @assert number_of_zones_trip == number_of_zones # Check if number_of_zone is same in both txt files
    @assert total_od_flow > 0

    travel_demand = zeros(number_of_zones, number_of_zones)
    od_pairs = Array((Int64,Int64),0)
    while (line=readline(f)) != ""
        if contains(line, "Origin")
            origin = parseint( split(line)[2] )
        elseif contains(line, ";")
            pairs = split(line, ";")
            for i=1:size(pairs)[1]
                if contains(pairs[i], ":")
                    pair = split(pairs[i], ":")
                    destination = parseint( strip(pair[1]) )
                    od_flow = parsefloat( strip(pair[2]) )
                    travel_demand[origin, destination] = od_flow
                    push!(od_pairs, (origin, destination))
                    # println("origin=$origin, destination=$destination, flow=$od_flow")
                end
            end
        end
    end

    # Preparing data to return
    ta_data = TA_Data(
        network_name,
        number_of_zones,
        number_of_nodes,
        first_thru_node,
        number_of_links,
        start_node,
        end_node,
        capacity,
        link_length,
        free_flow_time,
        B,
        power,
        speed_limit,
        toll,
        link_type,
        total_od_flow,
        travel_demand,
        od_pairs,
        toll_factor,
        distance_factor,
        best_objective)

    return ta_data

end # end of load_network function
