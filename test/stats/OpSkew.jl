using Test
using StatsBase


@testset "OpSkew: Biased" begin
    window_size = 4
    op = OpSkew{Float64,Float64}(window_size; corrected=false, next=OpReturn())

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    # import pandas as pd
    # from scipy.stats import skew
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #     print(df.rolling(4, min_periods=1).apply(skew).to_string(index=False))
    #     print(df.rolling(4, min_periods=1).skew(bias=True).to_string(index=False))
    expected = [
        0.00000000
        0.00000000
        0.70694579
        1.14487050
        -0.46274238
        1.14957106
        -0.83410123
    ]

    @test isnan(op(vals[1]))
    @test op(vals[2]) ≈ expected[2] atol = 1e-6
    @test op(vals[3]) ≈ expected[3] atol = 1e-6
    @test op(vals[4]) ≈ expected[4] atol = 1e-6
    @test op(vals[5]) ≈ expected[5] atol = 1e-6
    @test op(vals[6]) ≈ expected[6] atol = 1e-6
    @test op(vals[7]) ≈ expected[7] atol = 1e-6
end


@testset "OpSkew: Unbiased" begin
    window_size = 4
    op = OpSkew{Float64,Float64}(window_size; corrected=true, next=OpReturn())

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    # import pandas as pd
    # from scipy.stats import skew
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #     print(df.rolling(4, min_periods=1).skew().to_string(index=False))
    #     print(df.rolling(4, min_periods=1).apply(lambda x: skew(x, bias=False)).to_string(index=False))
    expected = [
        NaN
        NaN
        1.73165647
        1.98297388
        -0.80149332
        1.99111548
        -1.44470572
    ]

    @test isnan(op(vals[1]))
    @test isnan(op(vals[2]))
    @test op(vals[3]) ≈ expected[3] atol = 1e-6
    @test op(vals[4]) ≈ expected[4] atol = 1e-6
    @test op(vals[5]) ≈ expected[5] atol = 1e-6
    @test op(vals[6]) ≈ expected[6] atol = 1e-6
    @test op(vals[7]) ≈ expected[7] atol = 1e-6
end

@testset "OpSkew: Window size 1" begin
    window_size = 1
    op = OpSkew{Float64,Float64}(window_size; next=OpReturn())
    @test isnan(op(10.0))
    @test isnan(op(20.0))
    @test isnan(op(-1.0))
end
