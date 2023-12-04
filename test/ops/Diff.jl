using Test
using StreamOps


@testset "Diff lag=1 (default)" begin
    op = Diff{Float64}()
    @test op.lag == 1
    @test op(5.0) == 5.0
    @test op(6.0) == 1.0
    @test op(5.5) == -0.5
    @test op(8.0) == 2.5

    op = Diff{Float64}(1; init_value=-1.0)
    @test op(5.0) == 6.0
    @test op(6.0) == 1.0
end

@testset "Diff lag=3" begin
    op = Diff{Float64}(3)
    @test op(5.0) == 5.0 # init_value = 0.0
    @test op(6.0) == 6.0 # init_value = 0.0
    @test op(5.5) == 5.5 # init_value = 0.0
    @test op(8.0) == 3.0

    op = Diff{Float64}(3; init_value=-1.0)
    @test op(5.0) == 5.0+1.0 # init_value = -1.0
    @test op(6.0) == 6.0+1.0 # init_value = -1.0
    @test op(5.5) == 5.5+1.0 # init_value = -1.0
    @test op(8.0) == 3.0
end
