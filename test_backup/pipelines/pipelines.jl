using Test
using StreamOps

@testset verbose = true "Pipelines" begin

    @testset "Two operations" begin
        pipe = @streamops Transform(x -> x) Transform(x -> x^2)
        @test pipe(1) == 1
    end

    @testset "Three operations" begin
        pipe = @streamops Transform(x -> x * x) Lag{Float64}(1)
        @test pipe(1.5) == 0.0 # first value
        @test pipe(2.0) == 1.5^2 # second value
        @test pipe(3.0) == 2.0^2 # third value
    end

    @testset "Three operations multi-line block syntax" begin
        pipe = @streamops begin
            Transform(x -> x * x)
            Lag{Float64}(1)
        end
        @test pipe(1.5) == 0.0 # first value
        @test pipe(2.0) == 1.5^2 # second value
        @test pipe(3.0) == 2.0^2 # third value
    end

    @testset "Two operations using constructor and instance variable" begin
        last_op = Transform(x -> x)
        pipe = @streamops Transform(x -> x * x) last_op
        @test pipe(2) == 4
    end

    @testset "Capture variables passed to @streamops Ops" begin
        function test_fn(pipe)
            pipe.([1, 2, 3])
        end

        # Test with pre-allocated array
        output = Int64[]
        pipe = @streamops begin
            Transform(x -> x^2)
            Collect(output)
        end
        test_fn(pipe)
        @test all(output .== [1, 2, 3] .^ 2)
    end

end
