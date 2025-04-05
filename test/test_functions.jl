
function test_tntp()
    data_dir = TrafficAssignment.datapath()

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
