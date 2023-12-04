using Test
using Statistics


@testset "ZScore: Uncorreted std" begin
    window_size = 4
    corrected = false
    op = ZScore{Float64,Float64}(window_size; corrected=corrected)
    @test op.corrected == corrected

    vals = [
        5.0
        3.2
        1.4
        6.7
        4.5
        -13.4
    ]

    @test isnan(op(vals[1]))

    for i in firstindex(vals)+1:lastindex(vals)
        wnd = vals[max(1, i-window_size+1):i]
        @test op(vals[i]) ≈ (vals[i] - mean(wnd)) / std(wnd; corrected=corrected)
    end
end


@testset "ZScore: Corrected std" begin
    window_size = 4
    corrected = true
    op = ZScore{Float64,Float64}(window_size; corrected=corrected)
    @test op.corrected == corrected

    vals = [
        5.0
        3.2
        1.4
        6.7
        4.5
        -13.4
    ]

    @test isnan(op(vals[1]))

    for i in firstindex(vals)+1:lastindex(vals)
        wnd = vals[max(1, i-window_size+1):i]
        @test op(vals[i]) ≈ (vals[i] - mean(wnd)) / std(wnd; corrected=corrected)
    end
end


@testset "ZScore: Constant (uncorrected bias)" begin
    window_size = 5
    op = ZScore{Float64,Float64}(window_size; corrected=false)
    @test op.corrected == false

    @test isnan(op(1.0))
    @test isnan(op(1.0))
    @test isnan(op(1.0))
end


@testset "ZScore: Constant (corrected bias)" begin
    window_size = 5
    op = ZScore{Float64,Float64}(window_size)
    @test op.corrected == true

    @test isnan(op(1.0))
    @test isnan(op(1.0))
    @test isnan(op(1.0))
end
