using Test
using Statistics


@testset "OpZScore: Uncorreted std" begin
    window_size = 4
    corrected = false
    op = OpZScore{Float64,Float64}(window_size; corrected=corrected, next=OpReturn())
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


@testset "OpZScore: Correted std" begin
    window_size = 4
    corrected = true
    op = OpZScore{Float64,Float64}(window_size; corrected=corrected, next=OpReturn())
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


@testset "OpZScore: Constant (uncorrected bias)" begin
    window_size = 5
    op = OpZScore{Float64,Float64}(window_size; corrected=false, next=OpReturn())
    @test op.corrected == false

    @test isnan(op(1.0))
    @test isnan(op(1.0))
    @test isnan(op(1.0))
end


@testset "OpZScore: Constant (corrected bias)" begin
    window_size = 5
    op = OpZScore{Float64,Float64}(window_size; next=OpReturn())
    @test op.corrected == true

    @test isnan(op(1.0))
    @test isnan(op(1.0))
    @test isnan(op(1.0))
end
