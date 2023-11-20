using Test
using StreamOps


@testset "OpForwardFill with numbers" begin
    op = OpForwardFill{Float64}(x -> isnan(x); next=OpReturn())
    @test op(NaN) == 0
    @test op(NaN) == 0
    @test op(1.0) == 1.0
    @test op(NaN) == 1.0
    @test op(NaN) == 1.0
    @test op(-1.0) == -1.0
end

@testset "OpForwardFill with numbers 2" begin
    op = OpForwardFill{Float64}(x -> x < 0; next=OpReturn(), init_value=NaN)
    @test isnan(op(-10.0))
    @test isnan(op(-1.0))
    @test op(1.0) == 1.0
    @test op(2.0) == 2.0
end

@testset "OpForwardFill with text" begin
    op = OpForwardFill{String}(x -> x == ""; next=OpReturn(), init_value="init")
    @test op("") == "init"
    @test op("test") == "test"
    @test op("") == "test"
    @test op("test2") == "test2"
end
