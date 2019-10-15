using TrafficAssignment
using Test, LinearAlgebra
using DelimitedFiles


include("test_functions.jl")


test_tntp()

summarize_ta_data()

data_time = time()
ta_data = load_ta_network("SiouxFalls")
println("Data Loading Completed, time:", time() - data_time, " seconds")


@testset "Various FW Methods" begin
    ta_data = load_ta_network("SiouxFalls")

    link_volume, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:bfw, step=:exact, log=:on, tol=1e-3, max_iter_no=5)
    @test abs( objective - 4.963799502172654e6 ) < 1e6

    link_volume, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, step=:newton, log=:on, tol=1e-3, max_iter_no=5)
    @test abs( objective - 4.963799502172654e6 ) < 1e6

    link_volume, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:fw, step=:exact, log=:on, tol=1e-3, max_iter_no=5)
    @test abs( objective - 4.963799502172654e6 ) < 1e6
end

@testset "Sioux Falls" begin
    ta_data = load_ta_network("SiouxFalls")
    link_volume, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, step=:newton, log=:on, tol=1e-5, max_iter_no=50000)
    solution, header = readdlm("SiouxFalls_flow.csv", ',', header=true)
    solution_flow = Float64.(solution[:, 3])
    @test norm(link_volume - solution_flow) / norm(solution_flow) < 0.01
end


@testset "Anaheim" begin
    ta_data = load_ta_network("Anaheim")
    link_volume, link_travel_time, objective = ta_frank_wolfe(ta_data, method=:cfw, step=:newton, log=:on, tol=1e-5, max_iter_no=50000)
    solution, header = readdlm("Anaheim_flow.csv", ',', header=true)
    solution_flow = Float64.(solution[:, 3])
    @test norm(link_volume - solution_flow) / norm(solution_flow) < 0.01
end
