using Test


@testset "EWStd: No bias correction" begin
    alpha = 0.9
    op = EWStd{Float64}(; alpha=alpha, corrected=false)
    @test op.corrected == false
    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    # import pandas as pd
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #   df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #   print(df.ewm(alpha=0.9, adjust=False).std(bias=True).to_string(index=False))
    # https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1938
    expected = [
        0.00000000
        14.55000000
        4.86321653
        1.69491703
        2.09835672
        45.70194245
        161.07993016
    ]

    @test op(vals[1]) ≈ expected[1] atol = 1e-6
    @test op(vals[2]) ≈ expected[2] atol = 1e-6
    @test op(vals[3]) ≈ expected[3] atol = 1e-6
    @test op(vals[4]) ≈ expected[4] atol = 1e-6
    @test op(vals[5]) ≈ expected[5] atol = 1e-6
    @test op(vals[6]) ≈ expected[6] atol = 1e-6
    @test op(vals[7]) ≈ expected[7] atol = 1e-6
end


@testset "EWStd: With bias correction" begin
    alpha = 0.9
    op = EWStd{Float64}(; alpha=alpha)
    @test op.corrected == true
    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    # import pandas as pd
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #   df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #   print(df.ewm(alpha=0.9, adjust=True).std(bias=False).to_string(index=False))
    # https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1938
    expected = [
        NaN
        34.29467889
        10.88025528
        3.82606368
        4.90600478
        107.18090709
        377.76599594
    ]

    @test isnan(op(vals[1]))
    @test op(vals[2]) ≈ expected[2] atol = 1e-6
    @test op(vals[3]) ≈ expected[3] atol = 1e-6
    @test op(vals[4]) ≈ expected[4] atol = 1e-6
    @test op(vals[5]) ≈ expected[5] atol = 1e-6
    @test op(vals[6]) ≈ expected[6] atol = 1e-6
    @test op(vals[7]) ≈ expected[7] atol = 1e-6
end


@testset "EWStd: Constant (uncorrected)" begin
    alpha = 0.9
    op = EWStd{Float64}(; alpha=alpha, corrected=false)
    @test op.corrected == false

    vals = [1.0 1.0 1.0]

    @test op(vals[1]) ≈ 0.0
    @test op(vals[2]) ≈ 0.0
    @test op(vals[3]) ≈ 0.0
end


@testset "EWStd: Constant (corrected)" begin
    alpha = 0.9
    op = EWStd{Float64}(; alpha=alpha)
    @test op.corrected == true

    vals = [1.0 1.0 1.0]

    @test isnan(op(vals[1]))
    @test op(vals[2]) ≈ 0.0
    @test op(vals[3]) ≈ 0.0
end
