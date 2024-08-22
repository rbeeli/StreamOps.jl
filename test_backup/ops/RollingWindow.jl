using Test
using StreamOps

@testset "WindowBuffer" begin
    window_size = 3
    op = WindowBuffer{Int}(window_size; init_value=-1)

    @test length(op.buffer) == window_size
    @test all(op.buffer .== -1) # check initial values

    @test all(op(1) .== [-1, -1, 1])
    @test all(op(2) .== [-1, 1, 2])
    @test all(op(3) .== [1, 2, 3])
    @test all(op(4) .== [2, 3, 4])
end
