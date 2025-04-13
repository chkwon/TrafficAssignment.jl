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
        @test TA.nb_nodes(problem) == 24
        @test TA.nb_links(problem) == 76
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

    @testset "Comparing results" begin
        @testset "Sioux Falls" begin
            problem = TrafficAssignmentProblem("SiouxFalls")
            (; optimal_flow_volume) = problem
            flow_volume = solve_frank_wolfe(problem; verbose=false, max_iteration=10_000)
            @test reldist(optimal_flow_volume, flow_volume) < 1e-4
            @test TA.objective(problem, flow_volume) <
                1.05 * TA.objective(problem, optimal_flow_volume)
        end

        @testset "Anaheim" begin
            problem = TrafficAssignmentProblem("Anaheim")
            (; optimal_flow_volume) = problem
            flow_volume = solve_frank_wolfe(problem; verbose=false, max_iteration=1000)
            @test_broken reldist(optimal_flow_volume, flow_volume) < 1e-2
            @test TA.objective(problem, flow_volume) <
                1.05 * TA.objective(problem, optimal_flow_volume)
        end
    end

    @testset "Plotting" begin
        plot_network(TrafficAssignmentProblem("SiouxFalls"))
        plot_network_osm(TrafficAssignmentProblem("SiouxFalls"))
    end
end
