using Test
using StreamOps


@testset "OpDropIf" begin
    # drop if negative number
    op = OpDropIf(x -> x < 0; next=OpReturn())
    @test op(1) == 1
    @test isnothing(op(-2))
    @test op(3) == 3

    # no drop
    op = OpDropIf(x -> false; next=OpReturn())
    @test op(1) == 1
    @test op(2) == 2
    @test op(3) == 3

    # custom return value if dropped
    op = OpDropIf(x -> x < 0; next=OpReturn(), dropped_ret_val=:dropped)
    @test op(1) == 1
    @test op(-2) == :dropped
    @test op(3) == 3
end
