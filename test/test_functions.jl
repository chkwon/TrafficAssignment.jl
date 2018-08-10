
function test_tntp()
  data_dir = download_tntp()

  # Test
  for d in readdir(data_dir)
    if isdir(joinpath(data_dir, d))
      try
        read_ta_network(d)
        load_ta_network(d)
        @info "Network '$d' is OK."
      catch e
        @show e
        @warn "Network '$d' is not usable."
      end
    end
  end
end

function summarize_ta_data()
  data_dir = download_tntp()

  # Test
  dic = Dict()
  for d in readdir(data_dir)
    if isdir(joinpath(data_dir, d))
      try
        network_data_file, trip_table_file = read_ta_network(d)
        number_of_zones, number_of_links, number_of_nodes = read_ta_summary(network_data_file)
        dic[d] = (number_of_zones, number_of_links, number_of_nodes)
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

  println("-"^(17+sum(max_len)))
  println("| $(format(max_len[1],"Network")) | $(format(max_len[2],"Zones")) | $(format(max_len[3],"Links")) | $(format(max_len[4],"Nodes")) |")
  println("| $(format(max_len[1],":---")) | $(format(max_len[2],"---:")) | $(format(max_len[3],"---:")) | $(format(max_len[4],"---:")) |")
  for net in sort(dic)
    println("| $(format(max_len[1],net[1])) | $(format(max_len[2],net[2][1])) | $(format(max_len[3],net[2][2])) | $(format(max_len[4],net[2][3])) |")
  end
  println("-"^(17+sum(max_len)))

  return dic
end

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
