using Test
using StreamOps


@testset "OpDiff lag=1 (default)" begin
    op = OpDiff{Float64}(; next=OpReturn())
    @test op.lag == 1
    @test op(5.0) == 5.0
    @test op(6.0) == 1.0
    @test op(5.5) == -0.5
    @test op(8.0) == 2.5

    op = OpDiff{Float64}(1; init_value=-1.0, next=OpReturn())
    @test op(5.0) == 6.0
    @test op(6.0) == 1.0
end

@testset "OpDiff lag=3" begin
    op = OpDiff{Float64}(3; next=OpReturn())
    @test op(5.0) == 5.0 # init_value = 0.0
    @test op(6.0) == 6.0 # init_value = 0.0
    @test op(5.5) == 5.5 # init_value = 0.0
    @test op(8.0) == 3.0

    op = OpDiff{Float64}(3; init_value=-1.0, next=OpReturn())
    @test op(5.0) == 5.0+1.0 # init_value = -1.0
    @test op(6.0) == 6.0+1.0 # init_value = -1.0
    @test op(5.5) == 5.5+1.0 # init_value = -1.0
    @test op(8.0) == 3.0
end
