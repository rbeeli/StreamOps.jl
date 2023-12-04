using Test
using StreamOps


@testset verbose = true "Func" begin

    @testset "identity" begin
        op = Func(identity)
        @test op(7) == 7
    end

    @testset "x*x" begin
        op = Func(x -> x * x)
        @test op(5) == 25
    end

    @testset "multiple" begin
        pipe = @streamops begin
            Func(x -> x * x)
            Func(x -> x - 1)
        end
        @test pipe(5) == 24
    end

    @testset "block wrapped" begin
        pipe = @streamops begin
            Func(x -> begin
                x * x
            end)
        end
        @test pipe(5) == 25
    end

end
