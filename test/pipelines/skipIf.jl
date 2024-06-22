using Test
using StreamOps

@testset "@skipIf" begin
    counter = 0
    pipe = @streamops begin
        Transform(x -> x)
        @skipIf x -> x <= 0
        Transform(x -> begin
            counter += 1
            x
        end)
    end

    @test pipe(1.5) == 1.5
    @test isnothing(pipe(-0.5))
    @test pipe(3.0) == 3.0
    @test counter == 2
end
