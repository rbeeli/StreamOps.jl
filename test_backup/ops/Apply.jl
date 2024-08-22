using Test
using StreamOps

@testset verbose = true "Apply" begin
    mutable struct TestInput
        value::Int
    end

    @testset "identity" begin
        op = Apply(identity)
        @test op(7) == 7
    end

    @testset "x*x" begin
        op = Apply(x -> x.value *= x.value)
        @test op(TestInput(5)).value == 25
    end

    @testset "multiple" begin
        pipe = @streamops begin
            Apply(x -> x.value *= x.value)
            Apply(x -> x.value -= 1)
        end
        @test pipe(TestInput(5)).value == 24
    end

    @testset "block wrapped" begin
        pipe = @streamops begin
            Apply(x -> begin
                x.value *= x.value
            end)
        end
        @test pipe(TestInput(5)).value == 25
    end

end
