using Test
using StreamOps


@testset "@filter" begin
    counter = 0
    pipe = @streamops begin
        Func(x -> x)
        @filter x -> x > 0
        Func(x -> begin
            counter += 1
            x
        end)
    end

    @test pipe(1.5) == 1.5
    @test isnothing(pipe(-0.5))
    @test pipe(3.0) == 3.0
    @test counter == 2
end
