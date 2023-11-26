using Test
using StreamOps


@testset verbose = true "Pipelines" begin

    @testset "Single operation" begin
        # using operation directly
        op = OpReturn()
        @test op(1) == 1

        # using pipeline
        pipe = @pipeline OpReturn()
        @test pipe(1) == 1
    end

    @testset "Two operations" begin
        pipe = @pipeline OpReturn() OpNone()
        @test pipe(1) == 1

        pipe = @pipeline OpFunc(x -> x * x) OpReturn()
        @test pipe(2) == 4
    end

    @testset "Three operations" begin
        pipe = @pipeline OpFunc(x -> x * x) OpLag{Float64}(1) OpReturn()
        @test pipe(1.5) == 0.0 # first value
        @test pipe(2.0) == 1.5^2 # second value
        @test pipe(3.0) == 2.0^2 # third value
    end

    @testset "Three operations multi-line block syntax" begin
        pipe = @pipeline begin
            OpFunc(x -> x * x)
            OpLag{Float64}(1)
            OpReturn()
        end
        @test pipe(1.5) == 0.0 # first value
        @test pipe(2.0) == 1.5^2 # second value
        @test pipe(3.0) == 2.0^2 # third value
    end

    @testset "Two operations using constructor and instance variable" begin
        last_op = OpReturn()
        pipe = @pipeline OpFunc(x -> x * x) last_op
        @test pipe(2) == 4
    end

    @testset "Capture variables passed to @pipeline Ops" begin
        function test_fn(pipe)
            pipe.([1, 2, 3])
        end

        # Test with pre-allocated array
        output = Int64[]
        pipe = @pipeline begin
            OpFunc(x -> x^2)
            OpCollect(; values=output)
        end
        test_fn(pipe)
        @test all(output .== [1, 2, 3] .^ 2)
    end

    @testset "Capture variables passed to manual pipeline" begin
        function test_fn(pipe)
            pipe.([1, 2, 3])
        end

        # Test with pre-allocated array
        output = Int64[]
        pipe = OpFunc(x -> x^2; next=OpCollect(; values=output))
        test_fn(pipe)
        @test all(output .== [1, 2, 3] .^ 2)
    end

end
