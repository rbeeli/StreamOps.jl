using Test
using StreamOps

@testset "Accumulate manual function" begin
    op = Accumulate((acc, val) -> acc + val; init=0)
    @test op(1) == 1
    @test op(2) == 1 + 2
    @test op(3) == 1 + 2 + 3
end

@testset "Accumulate manual function non-zero init" begin
    op = Accumulate((acc, val) -> acc + val; init=10)
    @test op(1) == 10 + 1
    @test op(2) == 10 + 1 + 2
    @test op(3) == 10 + 1 + 2 + 3
end

@testset "Accumulate +" begin
    op = Accumulate(+; init=0)
    @test op(1) == 1
    @test op(2) == 1 + 2
    @test op(3) == 1 + 2 + 3
end
