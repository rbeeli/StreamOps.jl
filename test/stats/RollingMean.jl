using Test

@testset "RollingMean: Basic Functionality" begin
    window_size = 3
    op = RollingMean{Float64,Float64}(window_size)
    @test op(10.0) == 10.0
    @test op(20.0) == 15.0
    @test op(-30.0) == 0.0
    @test op(0.0) == -10.0 / 3.0

    # edge case - window size 1
    window_size = 1
    op = RollingMean{Float64,Float64}(window_size)
    @test op(10.0) == 10.0
    @test op(20.0) == 20.0
    @test op(-30.0) == -30.0
end

@testset "RollingMean: Window Size Respect" begin
    window_size = 2
    op = RollingMean{Float64,Float64}(window_size)
    op(100.0)
    op(200.0)
    @test op(300.0) == 250.0 # this should drop the first value (100)
    @test op.buffer == [200.0, 300.0] # Mean with sliding window
end

@testset "RollingMean: Integer input, float output" begin
    window_size = 2
    op = RollingMean{Int64,Float64}(window_size)
    op(100)
    op(200)
    @test op(300) == 250.0 # this should drop the first value (100)
    @test op.buffer == [200.0, 300.0] # Mean with sliding window
end
