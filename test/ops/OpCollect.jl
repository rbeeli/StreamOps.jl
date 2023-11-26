using Test
using StreamOps


@testset "OpCollect" begin
    op = OpCollect{Float64}(; next=OpReturn())
    @test op(1.0) == 1.0
    @test op(2.0) == 2.0
    @test op(3.0) == 3.0
    @test all(op.values .== [1.0, 2.0, 3.0])

    op = OpCollect{String}(; next=OpReturn())
    @test op("test1") == "test1"
    @test op("test2") == "test2"
    @test op("test3") == "test3"
    @test all(op.values .== ["test1", "test2", "test3"])

    # Test with pre-allocated array
    values = Int64[]
    op = OpCollect(; values=values, next=OpReturn())
    @test op(1) == 1
    @test op(2) == 2
    @test op(3) == 3
    @test values == op.values
    @test all(op.values .== [1, 2, 3])
end


@testset "OpCollect inside pipeline" begin
    # Test with pre-allocated array
    output = Int64[]
    pipe = @pipeline begin
        OpFunc(x -> x^2)
        OpCollect(; values=output)
        OpReturn()
    end
    @test pipe(1) == 1
    @test pipe(2) == 2^2
    @test pipe(3) == 3^2
    @test all(output .== [1, 2, 3] .^ 2)
end
