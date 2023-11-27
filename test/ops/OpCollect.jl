using Test
using StreamOps


@testset "OpCollect" begin
    op = OpCollect{Float64}(; next=OpReturn())
    @test op(1.0) == 1.0
    @test op(2.0) == 2.0
    @test op(3.0) == 3.0
    @test all(op.out .== [1.0, 2.0, 3.0])

    op = OpCollect{String}(; next=OpReturn())
    @test op("test1") == "test1"
    @test op("test2") == "test2"
    @test op("test3") == "test3"
    @test all(op.out .== ["test1", "test2", "test3"])

    # Test with pre-allocated array
    out = Int64[]
    op = OpCollect(; out=out, next=OpReturn())
    @test op(1) == 1
    @test op(2) == 2
    @test op(3) == 3
    @test out == op.out
    @test all(op.out .== [1, 2, 3])
end


@testset "OpCollect inside pipeline" begin
    # Test with pre-allocated array
    out = Int64[]
    pipe = @pipeline begin
        OpFunc(x -> x^2)
        OpCollect(; out=out)
        OpReturn()
    end
    @test pipe(1) == 1
    @test pipe(2) == 2^2
    @test pipe(3) == 3^2
    @test all(out .== [1, 2, 3] .^ 2)
end
