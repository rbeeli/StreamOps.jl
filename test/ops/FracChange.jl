using Test
using StreamOps

@testset "FracChange: Basic Functionality" begin
    op = FracChange{Int}(; init_value=100)
    @test op(120) ≈ 120 / 100 - 1.0
    @test op(150) ≈ 150 / 120 - 1.0
end

@testset "FracChange: Division by Zero for Non-Real Types" begin
    op = FracChange{Int}(; init_value=0)
    @test op(50) == 0 # No percentage change for non-real types
end

@testset "FracChange: Division by Zero for Real Types" begin
    op = FracChange{Float64}()
    @test isnan(op(50.0))
    @test op(100.0) == 100 / 50 - 1.0
end
