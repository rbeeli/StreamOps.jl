using Test
using StreamOps


@testset "Collect" begin
    op = Collect{Float64}()
    @test all(op(1.0) .== [1.0])
    @test all(op(2.0) .== [1.0, 2.0])
    @test all(op(3.0) .== [1.0, 2.0, 3.0])
    @test all(op.out .== [1.0, 2.0, 3.0])

    op = Collect{String}()
    @test all(op("test1") .== ["test1"])
    @test all(op("test2") .== ["test1", "test2"])
    @test all(op("test3") .== ["test1", "test2", "test3"])
    @test all(op.out .== ["test1", "test2", "test3"])

    # Test with pre-allocated array
    out = Int64[]
    op = Collect(out)
    @test all(op(1) .== [1])
    @test all(op(2) .== [1, 2])
    @test all(op(3) .== [1, 2, 3])
    @test out == op.out
    @test all(op.out .== [1, 2, 3])
end


@testset "Collect inside pipeline" begin
    # Test with pre-allocated array
    out = Int64[]
    pipe = @streamops begin
        Func(x -> x^2)
        Collect(out)
    end
    @test all(pipe(1) .== [1])
    @test all(pipe(2) .== [1, 2^2])
    @test all(pipe(3) .== [1, 2^2, 3^2])
    @test all(out .== [1, 2, 3] .^ 2)
end
