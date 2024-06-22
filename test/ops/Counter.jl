using Test
using StreamOps

@testset "Counter" begin
    op = Counter()
    @test op(true) == 1
    @test op("test") == 2
    @test op(1.0) == 3
    @test op(1) == 4
end

@testset "Counter w/ init value" begin
    op = Counter(5)
    @test op(true) == 6
    @test op("test") == 7
    @test op(1.0) == 8
    @test op(1) == 9
end
