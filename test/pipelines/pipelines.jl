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

    @testset "Two operations using constructor and instance variable" begin
        last_op = OpReturn()
        pipe = @pipeline OpFunc(x -> x * x) last_op
        @test pipe(2) == 4
    end

end
