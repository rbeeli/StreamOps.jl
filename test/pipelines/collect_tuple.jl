using Test
using StreamOps


@testset "@collect_tuple" begin
    pipe = @streamops begin
        @collect_tuple begin
            Func(x -> x^2)
            Func(x -> x^2) |> Lag{Float32}(1)
        end
    end

    @test all(pipe(1.0) .== (1.0, 0.0f0))
    @test all(pipe(2.0) .== (4.0, 1.0f0))
    @test all(pipe(3.0) .== (9.0, 4.0f0))
    @test all(pipe(4.0) .== (16.0, 9.0f0))
    @test pipe(5.0) isa Tuple{Float64, Float32}
end
