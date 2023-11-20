using Test
using StreamOps


@testset "OpFracChange: Basic Functionality" begin
    op = OpFracChange{Int}(; init_value=100, next=OpReturn())
    @test op(120) ≈ 120 / 100 - 1.0
    @test op(150) ≈ 150 / 120 - 1.0
end

@testset "OpFracChange: Division by Zero for Non-Real Types" begin
    op = OpFracChange{Int}(; init_value=0, next=OpReturn())
    @test op(50) == 0 # No percentage change for non-real types
end

@testset "OpFracChange: Division by Zero for Real Types" begin
    op = OpFracChange{Float64}(; next=OpReturn())
    @test isnan(op(50.0))
    @test op(100.0) == 100 / 50 - 1.0
end
