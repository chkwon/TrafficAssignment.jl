# Sioux Falls network data
# http://www.bgu.ac.il/~bargera/tntp/

#Link travel time = free flow time * ( 1 + B * (flow/capacity)^Power ).
#Link generalized cost = Link travel time + toll_factor * toll + distance_factor * distance

number_of_links = 0

n = open("SiouxFalls_net.txt", "r")

while (line=readline(n)) != ""
    if contains(line, "<NUMBER OF ZONES>")
        number_of_zones = parseint( line[ search(line, '>')+1 : end-1 ] )
    elseif contains(line, "<NUMBER_OF_NODES>")
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
length = zeros(number_of_links)
free_flow_time = zeros(number_of_links)
B = zeros(number_of_links)
power = Array(Int, number_of_links)
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
        length[idx] = parsefloat(numbers[4])
        free_flow_time[idx] = parsefloat(numbers[5])
        B[idx] = parsefloat(numbers[6])
        power[idx] = parseint(numbers[7])
        speed_limit[idx] = parsefloat(numbers[8])
        toll[idx] = parsefloat(numbers[9])
        link_type[idx] = parseint(numbers[10])

        idx = idx + 1
    end
end



number_of_zones = 0
total_od_flow = 0

f = open("SiouxFalls_trips.txt", "r")

while (line=readline(f)) != ""
    if contains(line, "<NUMBER OF ZONES>")
        number_of_zones = parseint( line[ search(line, '>')+1 : end-1 ] )
    elseif contains(line, "<TOTAL OD FLOW>")
        total_od_flow = parsefloat( line[ search(line, '>')+1 : end-1 ] )
    elseif contains(line, "<END OF METADATA>")
        break
    end
end

@assert number_of_zones > 0
@assert total_od_flow > 0

travel_demand = zeros(number_of_zones, number_of_zones)
while (line=readline(f)) != ""
    if contains(line, "Origin")
        origin = parseint( split(line)[2] )
    elseif contains(line, ";")
        pairs = split(line, ";")
        for i=1:size(pairs)[1]
            if contains(pairs[i], ":")
                pair = split(pairs[i], ":")
                destination = parseint( pair[1] )
                od_flow = parsefloat( pair[2] )
                travel_demand[origin, destination] = od_flow
                # println("origin=$origin, destination=$destination, flow=$od_flow")
            end
        end
    end
end
