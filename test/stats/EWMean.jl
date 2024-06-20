using Test


@testset "EWMean: Initialization" begin
    op = EWMean{Float64}(; alpha=0.5)
    @test op.alpha == 0.5
    @test op.M == 0.0
    @test op.ci == 1.0
end

@testset "EWMean: Without bias correction" begin
    op = EWMean{Float64}(; alpha=0.9, corrected=false)

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    # import pandas as pd
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #     print(df.ewm(alpha=0.9, adjust=False).mean().to_string(index=False))    
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
    op = EWMean{Float64}(; alpha=0.9)

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    # import pandas as pd
    # with pd.option_context('display.float_format', '{:0.8f}'.format):
    #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
    #     print(df.ewm(alpha=0.9, adjust=True).mean().to_string(index=False))   
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


@testset "EWMean: With bias correction (R sample)" begin
    alpha = 0.3
    op = EWMean{Float64}(; alpha=alpha)

    vals = [1.0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0]

    expected = [
        1, 0.411764705882353, 0.223744292237443, 0.135412554283458, #
        0.0865818037575277, 0.0571439257166366, 0.365385791052037, #
        0.567416735650975, 0.702648817229494, 0.794447250592858, #
        0.857357006849418, 0.596539859754709, 0.415826992743039, #
        0.290227047109354, 0.202743599929962, 0.141717713044793
    ]

    for i in eachindex(vals)
        @test op(vals[i]) ≈ expected[i] atol = 1e-4
    end
end
