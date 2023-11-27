using Test
using StreamOps


@testset "OpBroadcast" begin
    op1 = OpCollect{Float64}()
    op2 = OpCollect{Float64}()
    op3 = OpCollect{Float64}()

    op = OpBroadcast(; next=[op1, op2, op3])

    op(1.0)
    @test op1.out == [1.0]
    @test op2.out == [1.0]
    @test op3.out == [1.0]
    
    op(2.0)
    @test all(op1.out .== [1.0, 2.0])
    @test all(op2.out .== [1.0, 2.0])
    @test all(op3.out .== [1.0, 2.0])
end
