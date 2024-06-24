using Test
using StreamOps

@testset "PctChange: Set first output" begin
    op = PctChange(; first_output=1.0)
    @test op(100) == 1.0
    @test op(120) ≈ 0.2
end

@testset "PctChange: Initialize first previous" begin
    op = PctChange(; init_prev=100.0)
    @test op(120) ≈ 0.2
    @test op(150) ≈ 0.25
end

@testset "PctChange: Division by zero" begin
    op = PctChange(; init_prev=0.0)
    @test isinf(op(50.0))
    @test op(100.0) ≈ 100 / 50 - 1.0
end

# @testset "PctChange: Division by Zero for Non-Real Types" begin
#     op = PctChange(; init=0)
#     @test op(50) == 0 # No percentage change for non-real types
# end
