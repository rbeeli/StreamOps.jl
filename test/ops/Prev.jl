using Test
using StreamOps

@testset "Prev" begin
    op = Prev{Int64}()
    @test op(1) == zero(typeof(1))
    @test op(2) == 1
    @test op(3) == 2

    op = Prev{Float64}()
    @test op(1.0) == zero(typeof(1.0))
    @test op(2.0) == 1.0
    @test op(3.0) == 2.0

    op = Prev{String}()
    @test op("test") == ""
    @test op("test2") == "test"
    @test op("test3") == "test2"
end
