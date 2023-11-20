using Test
using StreamOps


@testset "OpFunc" begin
    op = OpFunc(x -> x*x; next=OpReturn())
    @test op(5) == 25

    op = OpFunc(identity; next=OpReturn())
    @test op(7) == 7
end
