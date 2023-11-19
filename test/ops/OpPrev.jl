using Test
using StreamOps


@testset "OpPrev" begin
    op = OpPrev{Int64}(OpReturn())
    @test op(1) == zero(typeof(1))
    @test op(2) == 1
    @test op(3) == 2

    op = OpPrev{Float64}(OpReturn())
    @test op(1.0) == zero(typeof(1.0))
    @test op(2.0) == 1.0
    @test op(3.0) == 2.0

    op = OpPrev{String}(OpReturn())
    @test op("test") == ""
    @test op("test2") == "test"
    @test op("test3") == "test2"
end
