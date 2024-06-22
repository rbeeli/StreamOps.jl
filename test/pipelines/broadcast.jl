using Test
using StreamOps

@testset "@broadcast" begin
    op1 = Float64[]
    op2 = Float64[]
    op3 = Float64[]

    pipe = @streamops begin
        Transform(x -> x)
        @broadcast begin
            Collect{Float64}(op1)
            Collect{Float64}(op2)
            Collect{Float64}(op3)
        end
        Transform(x -> x * x)
    end

    @test pipe(1.0) == 1.0
    @test all(op1 .== [1.0])
    @test all(op2 .== [1.0])
    @test all(op3 .== [1.0])
    
    @test pipe(2.0) == 4.0
    @test all(op1 .== [1.0, 2.0])
    @test all(op2 .== [1.0, 2.0])
    @test all(op3 .== [1.0, 2.0])
end
