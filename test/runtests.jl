using TrafficAssignment
using Test, LinearAlgebra
using DelimitedFiles
using Aqua, JET, JuliaFormatter

include("test_functions.jl")

@testset verbose = true "TrafficAssignment" begin
    @testset "Formalities" begin
        @testset "Aqua" begin
            Aqua.test_all(TrafficAssignment)
        end
        @testset "JET" begin
            JET.test_package(TrafficAssignment; target_defined_modules=true)
        end
        @testset "JuliaFormatter" begin
            @test JuliaFormatter.format(TrafficAssignment; overwrite=false)
        end
    end

    test_tntp()

    summarize_ta_data()

    data_time = time()
    ta_data = load_ta_network("SiouxFalls")
    println("Data Loading Completed, time:", time() - data_time, " seconds")

    @testset "Various FW Methods" begin
        ta_data = load_ta_network("SiouxFalls")

        @time link_volume, link_travel_time, objective = ta_frank_wolfe(
            ta_data; method=:bfw, step=:exact, log=:off, tol=1e-3, max_iter_no=5
        )
        @test abs(objective - 4.963799502172654e6) < 1e6

        @time link_volume, link_travel_time, objective = ta_frank_wolfe(
            ta_data; method=:cfw, step=:newton, log=:off, tol=1e-3, max_iter_no=5
        )
        @test abs(objective - 4.963799502172654e6) < 1e6

        @time link_volume, link_travel_time, objective = ta_frank_wolfe(
            ta_data; method=:fw, step=:exact, log=:off, tol=1e-3, max_iter_no=5
        )
        @test abs(objective - 4.963799502172654e6) < 1e6
    end

    @testset "Testing Sioux Falls" begin
        ta_data = load_ta_network("SiouxFalls")
        @time link_volume, link_travel_time, objective = ta_frank_wolfe(
            ta_data; method=:cfw, step=:newton, log=:off, tol=1e-5, max_iter_no=50000
        )
        solution, header = readdlm("SiouxFalls_flow.csv", ','; header=true)
        solution_flow = Float64.(solution[:, 3])
        @test norm(link_volume - solution_flow) / norm(solution_flow) < 0.01
    end

    @testset "Testing Anaheim" begin
        ta_data = load_ta_network("Anaheim")
        @time link_volume, link_travel_time, objective = ta_frank_wolfe(
            ta_data; method=:cfw, step=:newton, log=:off, tol=1e-5, max_iter_no=50000
        )
        solution, header = readdlm("Anaheim_flow.csv", ','; header=true)
        solution_flow = Float64.(solution[:, 3])
        @test norm(link_volume - solution_flow) / norm(solution_flow) < 0.01
    end

    summarize_ta_data(; markdown=true)
end
