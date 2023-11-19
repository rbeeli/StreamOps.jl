using Test
using StreamOps


@testset "OpLag" begin
    op = OpLag{Float64}(3, OpReturn())
    @test op(5.0) == zero(Float64)
    @test op(6.0) == zero(Float64)
    @test op(7.0) == zero(Float64)
    @test op(8.0) == 5.0

    op = OpLag{Float64}(3, OpReturn(); init_value=-1.0)
    @test op(5.0) == -1.0
    @test op(6.0) == -1.0
    @test op(7.0) == -1.0
    @test op(8.0) == 5.0
end
