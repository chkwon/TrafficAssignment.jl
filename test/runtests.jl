using TrafficAssignment
using Test, LinearAlgebra, SparseArrays
using DelimitedFiles
using Aqua, Documenter, JET, JuliaFormatter
using CairoMakie

DocMeta.setdocmeta!(
    TrafficAssignment, :DocTestSetup, :(using TrafficAssignment); recursive=true
)

ENV["DATADEPS_ALWAYS_ACCEPT"] = true

@testset verbose = true "TrafficAssignment" begin
    @testset "Formalities" begin
        @testset "Aqua" begin
            Aqua.test_all(TrafficAssignment)
        end
        @testset "Doctests" begin
            Documenter.doctest(TrafficAssignment)
        end
        @testset "JET" begin
            JET.test_package(TrafficAssignment; target_defined_modules=true)
        end
        @testset "JuliaFormatter" begin
            @test JuliaFormatter.format(TrafficAssignment; overwrite=false)
        end
        @testset "Undocumented names" begin
            if isdefined(Base.Docs, :undocumented_names)
                @test isempty(Base.Docs.undocumented_names(TrafficAssignment))
            end
        end
    end

    @testset "Display" begin
        problem = TrafficAssignmentProblem("SiouxFalls")
        @test startswith(string(problem), "Traffic")
    end

    @testset "Read all instances" begin
        summary = TrafficAssignment.summarize_instances()
        @testset "$(row[:instance])" for row in eachrow(summary)
            if row[:instance] in ("Munich", "SymmetricaTestCase", "Sydney")
                @test_skip row[:valid]
            else
                @test row[:valid]
            end
        end
    end

    @testset "Frank-Wolfe Methods" begin
        problem = TrafficAssignmentProblem("SiouxFalls")

        link_volume, link_travel_time, objective = solve_frank_wolfe(
            problem; method=:bfw, step=:exact, log=:off, tol=1e-3, max_iter_no=5
        )
        @test abs(objective - 4.963799502172654e6) < 1e6

        link_volume, link_travel_time, objective = solve_frank_wolfe(
            problem; method=:cfw, step=:newton, log=:off, tol=1e-3, max_iter_no=5
        )
        @test abs(objective - 4.963799502172654e6) < 1e6

        link_volume, link_travel_time, objective = solve_frank_wolfe(
            problem; method=:fw, step=:exact, log=:off, tol=1e-3, max_iter_no=5
        )
        @test abs(objective - 4.963799502172654e6) < 1e6
    end

    @testset "Comparing results" begin
        @testset "Sioux Falls" begin
            problem = TrafficAssignmentProblem("SiouxFalls")
            I, J, n = problem.init_node, problem.term_node, problem.number_of_nodes
            link_volume, link_travel_time, objective = solve_frank_wolfe(
                problem; method=:cfw, step=:newton, log=:off, tol=1e-5, max_iter_no=50000
            )
            my_flow_volume = sparse(I, J, link_volume, n, n)
            @test norm(problem.optimal_flow_volume - my_flow_volume) /
                  norm(problem.optimal_flow_volume) < 0.01
        end

        @testset "Anaheim" begin
            problem = TrafficAssignmentProblem("Anaheim")
            I, J, n = problem.init_node, problem.term_node, problem.number_of_nodes
            link_volume, link_travel_time, objective = solve_frank_wolfe(
                problem; method=:cfw, step=:newton, log=:off, tol=1e-5, max_iter_no=50000
            )
            my_flow_volume = sparse(I, J, link_volume, n, n)
            @test norm(problem.optimal_flow_volume - my_flow_volume) /
                  norm(problem.optimal_flow_volume) < 0.01
        end
    end

    @testset "Plotting" begin
        plot_network(TrafficAssignmentProblem("SiouxFalls"))
    end
end
