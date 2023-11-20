using Test
using StreamOps


@testset "OpHook" begin
    ref = Ref{Bool}(false)
    op = OpHook(ref)
    op(true)
    @test ref[] == true # ensure Ref was updated, so OpHook was called
end
