using Test


@testset "EWMean: Initialization" begin
    alpha = 0.5
    op = EWMean{Float64}(; alpha=alpha)

    @test op.alpha == alpha
    @test op.M == 0.0
    @test op.extra == 1.0
end

@testset "EWMean: Without bias correction" begin
    alpha = 0.9
    op = EWMean{Float64}(; alpha=alpha, corrected=false)

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    # import pandas as pd
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #   df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #   print(df.ewm(alpha=0.9, adjust=False).mean().to_string(index=False))    
    expected = [
        50.00000000
        6.35000000
        1.62500000
        3.76250000
        -2.32375000
        134.76762500
        -346.52323750
    ]

    for i in eachindex(vals)
        @test op(vals[i]) ≈ expected[i] atol = 1e-6
    end
end

@testset "EWMean: With bias correction" begin
    alpha = 0.9
    op = EWMean{Float64}(; alpha=alpha)

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    # import pandas as pd
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #   df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #   print(df.ewm(alpha=0.9, adjust=True).mean().to_string(index=False))   
    expected = [
        50.00000000
        5.90909091
        1.57657658
        3.75787579
        -2.32427324
        134.76770977
        -346.52327715
    ]

    for i in eachindex(vals)
        @test op(vals[i]) ≈ expected[i] atol = 1e-6
    end
end
