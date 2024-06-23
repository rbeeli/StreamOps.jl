using Test
using StreamOps

@testset "FracChange: Set first output" begin
    op = FracChange(; first_output=1.0)
    @test op(100) == 1.0
    @test op(120) ≈ 0.2
end

@testset "FracChange: Initialize first previous" begin
    op = FracChange(; init_prev=100.0)
    @test op(120) ≈ 0.2
    @test op(150) ≈ 0.25
end

@testset "FracChange: Division by zero" begin
    op = FracChange(; init_prev=0.0)
    @test isinf(op(50.0))
    @test op(100.0) ≈ 100 / 50 - 1.0
end

# @testset "FracChange: Division by Zero for Non-Real Types" begin
#     op = FracChange(; init=0)
#     @test op(50) == 0 # No percentage change for non-real types
# end
