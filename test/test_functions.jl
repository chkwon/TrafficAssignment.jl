
function test_tntp()
  data_dir = download_tntp()

  # Test
  @testset "Loading Network Data" begin
    for d in readdir(data_dir)
      if isdir(joinpath(data_dir, d)) && d != "_scripts"
        @testset "$d" begin
          try
            read_ta_network(d)
            td = load_ta_network(d)
            @info "Network '$d' is OK."
            @test td.network_name == d
          catch e
            @show e
            @warn "Directory '$d' does not contain a compatible dataset."
          end
        end
      end
    end
  end
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
