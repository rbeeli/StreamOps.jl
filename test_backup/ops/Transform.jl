using Test
using StreamOps

@testset verbose = true "Transform" begin

    @testset "identity" begin
        op = Transform(identity)
        @test op(7) == 7
    end

    @testset "x*x" begin
        op = Transform(x -> x * x)
        @test op(5) == 25
    end

    @testset "multiple" begin
        pipe = @streamops begin
            Transform(x -> x * x)
            Transform(x -> x - 1)
        end
        @test pipe(5) == 24
    end

    @testset "block wrapped" begin
        pipe = @streamops begin
            Transform(x -> begin
                x * x
            end)
        end
        @test pipe(5) == 25
    end

end
