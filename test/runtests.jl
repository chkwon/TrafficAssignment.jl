using TrafficAssignment
import TrafficAssignment as TA
using Test, LinearAlgebra, SparseArrays
using DelimitedFiles
using Aqua, Documenter, JET, JuliaFormatter
using CairoMakie

DocMeta.setdocmeta!(
    TrafficAssignment, :DocTestSetup, :(using TrafficAssignment); recursive=true
)

ENV["DATADEPS_ALWAYS_ACCEPT"] = true

reldist(a, b) = norm(a - b) / norm(a)

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
        @testset "Undocumented names" begin
            if isdefined(Base.Docs, :undocumented_names)
                @test isempty(Base.Docs.undocumented_names(TrafficAssignment))
            end
        end
        @testset "Doctests" begin
            Documenter.doctest(TrafficAssignment)
        end
    end

    @testset "Parsing" begin
        problem = TrafficAssignmentProblem("TransportationNetworks", "Anaheim")
        @test TA.nb_nodes(problem) == 416
        @test TA.nb_links(problem) == 914
        @test TA.nb_zones(problem) == 38
        @test startswith(string(problem), "Traffic")

        problem = TrafficAssignmentProblem("UnifiedTrafficDataset", "01_San_Francisco")
        @test TA.nb_nodes(problem) == 4986
        @test TA.nb_links(problem) == 18002
        @test TA.nb_zones(problem) == 194
        @test startswith(string(problem), "Traffic")
    end

    @testset "Read all instances" begin
        summary = TrafficAssignment.summarize_instances()
        @testset "$(row[:instance])" for row in eachrow(summary)
            if row[:instance] == "Munich"
                @test_broken row[:valid]
            else
                @test row[:valid]
            end
        end
    end

    @testset "Comparing results" begin
        @testset "Sioux Falls" begin
            problem = TrafficAssignmentProblem("TransportationNetworks", "SiouxFalls")
            (; optimal_flow) = problem
            flow = solve_frank_wolfe(problem; verbose=false, max_iteration=1_000)
            @test reldist(optimal_flow, flow) < 1e-3
            @test TA.objective(problem, flow) < 1.05 * TA.objective(problem, optimal_flow)
        end

        @testset "Anaheim" begin
            problem = TrafficAssignmentProblem("TransportationNetworks", "Anaheim")
            (; optimal_flow) = problem
            flow = solve_frank_wolfe(problem; verbose=false, max_iteration=100)
            @test_broken reldist(optimal_flow, flow) < 1e-2
            @test TA.objective(problem, flow) < 1.05 * TA.objective(problem, optimal_flow)
        end
    end

    @testset "Plotting" begin
        plot_network(
            TrafficAssignmentProblem("TransportationNetworks", "SiouxFalls"); tiles=true
        )
        plot_network(
            TrafficAssignmentProblem("UnifiedTrafficDataset", "01_San_Francisco");
            tiles=false,
            zones=true,
        )
    end
end
