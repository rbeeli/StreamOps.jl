using Test
using Statistics


@testset "Std: Sample standard deviation" begin
    window_size = 5
    op = Std{Float64,Float64}(window_size)
    @test isnan(op(10.0))
    @test op(-30.0) ≈ std([10.0, -30.0])
    @test op(40.0) ≈ std([10.0, -30.0, 40.0])
    @test op(5.0) ≈ std([10.0, -30.0, 40.0, 5.0])
    @test op(15.0) ≈ std([10.0, -30.0, 40.0, 5.0, 15.0])
    @test op(25.0) ≈ std([-30.0, 40.0, 5.0, 15.0, 25.0])
    @test op(-1.0) ≈ std([40.0, 5.0, 15.0, 25.0, -1.0])

    # edge case - window size 1 (always NaN)
    window_size = 1
    op = Std{Float64,Float64}(window_size)
    @test isnan(op(10.0))
    @test isnan(op(20.0))
    @test isnan(op(-1.0))
end


@testset "Std: Population standard deviation" begin
    window_size = 5
    op = Std{Float64,Float64}(window_size; corrected=false)
    @test op(10.0) == 0.0
    @test op(-30.0) ≈ std([10.0, -30.0]; corrected=false)
    @test op(40.0) ≈ std([10.0, -30.0, 40.0]; corrected=false)
    @test op(5.0) ≈ std([10.0, -30.0, 40.0, 5.0]; corrected=false)
    @test op(15.0) ≈ std([10.0, -30.0, 40.0, 5.0, 15.0]; corrected=false)
    @test op(25.0) ≈ std([-30.0, 40.0, 5.0, 15.0, 25.0]; corrected=false)
    @test op(-1.0) ≈ std([40.0, 5.0, 15.0, 25.0, -1.0]; corrected=false)
end
