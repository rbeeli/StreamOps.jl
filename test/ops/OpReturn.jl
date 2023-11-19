using Test
using StreamOps


@testset "OpReturn" begin
    op = OpReturn()
    @test op(true) == true

    ref = Ref{Bool}(false)
    op = OpReturn(OpHook(ref, OpNone()))
    @test op(true) == true
    @test ref[] == true # ensure Ref was updated, so OpHook was calleds
end