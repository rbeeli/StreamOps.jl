using Test
using StreamOps

@testset "Print" begin
    op = Print()
    @test op("Print: 1") == "Print: 1"
end