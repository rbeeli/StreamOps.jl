using Test
using StreamOps


@testset "OpNone" begin
    op = OpNone()
    @test isnothing(op(1))

    op = OpNone(OpReturn())
    @test isnothing(op(0.0))
end