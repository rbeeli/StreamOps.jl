using Test
using StreamOps


@testset "OpPrint" begin
    op = OpPrint(OpReturn())
    @test op("OpPrint: 1") == "OpPrint: 1"
end