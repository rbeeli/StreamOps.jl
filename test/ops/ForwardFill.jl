using Test
using StreamOps

@testset "ForwardFill with numbers" begin
    op = ForwardFill{Float64}(x -> isnan(x))
    @test op(NaN) == 0
    @test op(NaN) == 0
    @test op(1.0) == 1.0
    @test op(NaN) == 1.0
    @test op(NaN) == 1.0
    @test op(-1.0) == -1.0
end

@testset "ForwardFill with numbers 2" begin
    op = ForwardFill{Float64}(x -> x < 0, init_value=NaN)
    @test isnan(op(-10.0))
    @test isnan(op(-1.0))
    @test op(1.0) == 1.0
    @test op(2.0) == 2.0
end

@testset "ForwardFill with text" begin
    op = ForwardFill{String}(x -> x == "", init_value="init")
    @test op("") == "init"
    @test op("test") == "test"
    @test op("") == "test"
    @test op("test2") == "test2"
end
