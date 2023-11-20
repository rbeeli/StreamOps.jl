using Test
using StreamOps


@testset "OpPrint" begin
    op = OpPrint(; next=OpReturn())
    @test op("OpPrint: 1") == "OpPrint: 1"
end