using OptimizationCallbacks
using Test
using Documenter
using Optimization
using ForwardDiff

doctest(OptimizationCallbacks)

## NOTE add JET to the test environment, then uncomment
using JET
@testset "static analysis with JET.jl" begin
    @test isempty(JET.get_reports(report_package(OptimizationCallbacks, target_modules=(OptimizationCallbacks,))))
end

## NOTE add Aqua to the test environment, then uncomment
@testset "QA with Aqua" begin
    import Aqua
    Aqua.test_all(OptimizationCallbacks; ambiguities = false)
    # testing separately, cf https://github.com/JuliaTesting/Aqua.jl/issues/77
    Aqua.test_ambiguities(OptimizationCallbacks)
end
