using Test
using StreamOps


@testset "OpReturn" begin
    op = OpReturn()
    @test op(true) == true

    # ensure next op is called
    ref = Ref{Bool}(false)
    op = OpReturn(; next=OpHook(ref))
    @test op(true) == true
    @test ref[] == true # ensure Ref was updated, so OpHook was called
end