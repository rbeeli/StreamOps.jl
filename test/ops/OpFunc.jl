using Test
using StreamOps


@testset "OpFunc" begin
    op = OpFunc(x -> x*x, OpReturn())
    @test op(5) == 25

    op = OpFunc(identity, OpReturn())
    @test op(op) == op
end
