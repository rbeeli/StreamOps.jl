using Test
using StreamOps

@testset "Hook" begin
    ref = Ref{Bool}(false)
    op = Hook(ref)
    op(true)
    @test ref[] == true # ensure Ref was updated, so Hook was called
end
