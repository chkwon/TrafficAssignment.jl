# Sioux Falls network data
# http://www.bgu.ac.il/~bargera/tntp/

#Link travel time = free flow time * ( 1 + b * (flow/capacity)^Power ).
#Link generalized cost = Link travel time + toll_factor * toll + distance_factor * distance

# Traffic Assignment Data structure
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

function net_dataframe(td::TA_Data)
    df = DataFrame()
    df.init_node = td.init_node
    df.term_node = td.term_node
    df.capacity = td.capacity
    df.link_length = td.link_length
    df.free_flow_time = td.free_flow_time
    df.b = td.b
    df.power = td.power
    df.speed_limit = td.speed_limit
    df.toll = td.toll
    df.link_type = td.link_type
    return df
end

search_sc(s,c) = something(findfirst(isequal(c), s), 0)


function download_tntp(force_download=false)
  ta_root_dir = joinpath(dirname(dirname(@__FILE__)))
  dest = ta_root_dir
  data_dir = joinpath(dest, "TransportationNetworks-$(TNTP_SHA)")


  # Download
  if !isdir(data_dir) || force_download
    if isdir(data_dir)
      rm(data_dir)
    end
    file = joinpath(ta_root_dir, "tntp.zip")
    dl = download("https://github.com/bstabler/TransportationNetworks/archive/$(TNTP_SHA).zip", file)
    run(unpack_cmd(file, dest, ".zip", ""))
    rm(file)
  end

  return data_dir
end

function read_ta_network(network_name)
  tntp_dir = download_tntp()
  network_dir = joinpath(tntp_dir, network_name)

  @assert ispath(network_dir)

  network_data_file = ""
  trip_table_file = ""

  for f in readdir(network_dir)
    if occursin(".zip", lowercase(f))
      zipfile = joinpath(network_dir, f)
      run(unpack_cmd(zipfile, network_dir, ".zip", ""))
      rm(zipfile)
    end
  end

  for f in readdir(network_dir)
    if occursin("_net", lowercase(f)) && occursin(".tntp", lowercase(f))
      network_data_file = joinpath(network_dir, f)
  elseif occursin("_trips", lowercase(f)) && occursin(".tntp", lowercase(f))
      trip_table_file = joinpath(network_dir, f)
    end
  end

  @assert network_data_file != ""
  @assert trip_table_file != ""

  return network_data_file, trip_table_file
end



function load_ta_network(network_name; best_objective=-1.0, toll_factor=0.0, distance_factor=0.0)
  network_data_file, trip_table_file = read_ta_network(network_name)

  load_ta_network(network_name, network_data_file, trip_table_file, best_objective=best_objective, toll_factor=toll_factor, distance_factor=distance_factor)
end


function load_ta_network(network_name, network_data_file, trip_table_file; best_objective=-1.0, toll_factor=0.0, distance_factor=0.0)

    @assert ispath(network_data_file)
    @assert ispath(trip_table_file)

    ##################################################
    # Network Data
    ##################################################


    number_of_zones = 0
    number_of_links = 0
    number_of_nodes = 0
    first_thru_node = 0

    n = open(network_data_file, "r")

    while (line=readline(n)) != ""
        if occursin("<NUMBER OF ZONES>", line)
            number_of_zones = parse(Int, line[ search_sc(line, '>')+1 : end ] )
        elseif occursin("<NUMBER OF NODES>", line)
            number_of_nodes = parse(Int, line[ search_sc(line, '>')+1 : end ] )
        elseif occursin("<FIRST THRU NODE>", line)
            first_thru_node = parse(Int, line[ search_sc(line, '>')+1 : end ] )
        elseif occursin("<NUMBER OF LINKS>", line)
            number_of_links = parse(Int, line[ search_sc(line, '>')+1 : end ] )
        elseif occursin("<END OF METADATA>", line)
            break
        end
    end

    @assert number_of_links > 0

    init_node = Array{Int64}(undef, number_of_links)
    term_node = Array{Int64}(undef, number_of_links)
    capacity = zeros(number_of_links)
    link_length = zeros(number_of_links)
    free_flow_time = zeros(number_of_links)
    b = zeros(number_of_links)
    power = zeros(number_of_links)
    speed_limit = zeros(number_of_links)
    toll = zeros(number_of_links)
    link_type = Array{Int64}(undef, number_of_links)

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
            init_node[idx] = parse(Int64, numbers[1])
            term_node[idx] = parse(Int64, numbers[2])
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

    f = open(trip_table_file, "r")

    while (line=readline(f)) != ""
        if occursin("<NUMBER OF ZONES>", line)
            number_of_zones_trip = parse(Int, line[ search_sc(line, '>')+1 : end ] )
        elseif occursin("<TOTAL OD FLOW>", line)
            total_od_flow = parse(Float64, line[ search_sc(line, '>')+1 : end ] )
        elseif occursin("<END OF METADATA>", line)
            break
        end
    end

    @assert number_of_zones_trip == number_of_zones # Check if number_of_zone is same in both txt files
    @assert total_od_flow > 0

    travel_demand = zeros(number_of_zones, number_of_zones)
    od_pairs = Array{Tuple{Int64, Int64}}(undef, 0)

    origin = -1

    while !eof(f)
        line = readline(f)

        if line == ""
            origin = -1
            continue
        elseif occursin("Origin", line)
            origin = parse(Int, split(line)[2] )
        elseif occursin(";", line)
            pairs = split(line, ";")
            for i=1:size(pairs)[1]
                if occursin(":", pairs[i])
                    pair = split(pairs[i], ":")
                    destination = parse(Int64, strip(pair[1]) )
                    od_flow = parse(Float64, strip(pair[2]) )

                    # println("origin=$origin, destination=$destination, flow=$od_flow")

                    travel_demand[origin, destination] = od_flow
                    push!(od_pairs, (origin, destination))
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
        best_objective)

    return ta_data

end # end of load_network function


function read_ta_summary(network_data_file)
  @assert ispath(network_data_file)

  number_of_zones = 0
  number_of_links = 0
  number_of_nodes = 0
  first_thru_node = 0

  n = open(network_data_file, "r")

  search_sc(s,c) = something(findfirst(isequal(c), s), 0)

  while (line=readline(n)) != ""
      if occursin("<NUMBER OF ZONES>", line)
          number_of_zones = parse(Int, line[ search_sc(line, '>')+1 : end ] )
      elseif occursin("<NUMBER OF NODES>", line)
          number_of_nodes = parse(Int, line[ search_sc(line, '>')+1 : end ] )
      elseif occursin("<FIRST THRU NODE>", line)
          first_thru_node = parse(Int, line[ search_sc(line, '>')+1 : end ] )
      elseif occursin("<NUMBER OF LINKS>", line)
          number_of_links = parse(Int, line[ search_sc(line, '>')+1 : end ] )
      elseif occursin("<END OF METADATA>", line)
          break
      end
  end

  return number_of_zones, number_of_links, number_of_nodes
end



function summarize_ta_data(;markdown=false)
  data_dir = download_tntp()

  # Test
  df = DataFrame(Network = String[], Zones = Int[], Links = Int[], Nodes = Int[])
  dic = OrderedDict()
  for d in readdir(data_dir)
    if isdir(joinpath(data_dir, d))
      try
        network_data_file, trip_table_file = read_ta_network(d)
        number_of_zones, number_of_links, number_of_nodes = read_ta_summary(network_data_file)
        dic[d] = (number_of_zones, number_of_links, number_of_nodes)
        push!(df, (d, number_of_zones, number_of_links, number_of_nodes))
      catch

      end

    end
  end

  max_len = [0, 0, 0, 0]
  for net in sort(dic)
    max_len[1] = max( length(net[1]), max_len[1] )
    max_len[2] = max( length(digits(net[2][1])), max_len[2] )
    max_len[3] = max( length(digits(net[2][2])), max_len[3] )
    max_len[4] = max( length(digits(net[2][3])), max_len[4] )
  end

  function format(mlen, val)
    len = 0
    str = ""
    if isa(val, String)
      len = length(val)
      str = val * " "^(mlen - len + 1 )
    elseif isa(val, Number)
      len = length(digits(val))
      str = " "^(mlen - len + 1) * string(val)
    end
    return str
  end


  if markdown
      println("-"^(17+sum(max_len)))
      println("| $(format(max_len[1],"Network")) | $(format(max_len[2],"Zones")) | $(format(max_len[3],"Links")) | $(format(max_len[4],"Nodes")) |")
      println("| $(format(max_len[1],":---")) | $(format(max_len[2],"---:")) | $(format(max_len[3],"---:")) | $(format(max_len[4],"---:")) |")
      for net in sort(dic)
        println("| $(format(max_len[1],net[1])) | $(format(max_len[2],net[2][1])) | $(format(max_len[3],net[2][2])) | $(format(max_len[4],net[2][3])) |")
      end
      println("-"^(17+sum(max_len)))
  end

  if !markdown
      return df
  end
end # end of summarize_ta_data
