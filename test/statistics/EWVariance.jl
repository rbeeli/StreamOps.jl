using Test
using StreamOps

@testset verbose = true "EWVariance" begin

    @testset "alpha=0.9 corrected=false" begin
        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        avg = op!(g, :avg, EWVariance{Float64,Float64}(alpha=0.9, corrected=false), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, avg)
        bind!(g, avg, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        # import pandas as pd
        # with pd.option_context('display.float_format', '{:0.8f}'.format):
        #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
        #     print(df.ewm(alpha=0.9, adjust=False).var(bias=True).to_string(index=False))
        # https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1837
        expected = [
            0.00000000
            211.70250000
            23.65087500
            2.87274375
            4.40310094
            2088.66754336
            25946.74390167
        ]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 7)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(expected)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        @test output.operation.buffer ≈ expected
    end

    @testset "alpha=0.9 corrected=true" begin
        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        avg = op!(g, :avg, EWVariance{Float64,Float64}(alpha=0.9, corrected=true), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, avg)
        bind!(g, avg, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        # import pandas as pd
        # with pd.option_context('display.float_format', '{:0.8f}'.format):
        #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
        #     print(df.ewm(alpha=0.9, adjust=True).var(bias=False).to_string(index=False))
        # https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1837
        expected = [
            NaN
            1176.12500000
            118.37995495
            14.63876327
            24.06888292
            11487.74684538
            142707.14768944
        ]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 7)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(expected)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        @test output.operation.buffer ≈ expected
    end

    # @testset "alpha=0.3 corrected=true(default) (R sample)" begin
    #     g = StreamGraph()

    #     values = source!(g, :values, out=Float64, init=0.0)
    #     avg = op!(g, :avg, EWVariance{Float64,Float64}(alpha=0.3), out=Float64)
    #     output = sink!(g, :output, Buffer{Float64}())

    #     bind!(g, values, avg)
    #     bind!(g, avg, output)

    #     exe = compile_historic_executor(DateTime, g; debug=!true)

    #     vals = Float64[1.0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0]
    #     start = DateTime(2000, 1, 1)
    #     stop = DateTime(2000, 1, length(vals))
    #     adapters = [
    #         IterableAdapter(exe, values, [
    #             (DateTime(2000, 1, i), x)
    #             for (i, x) in enumerate(vals)
    #         ])
    #     ]
    #     run_simulation!(exe, adapters; start_time=start, end_time=stop)

    #     # R sample (see _reconcile/EWMA_bias.R)
    #     expected = [
    #         1, 0.411764705882353, 0.223744292237443, 0.135412554283458, #
    #         0.0865818037575277, 0.0571439257166366, 0.365385791052037, #
    #         0.567416735650975, 0.702648817229494, 0.794447250592858, #
    #         0.857357006849418, 0.596539859754709, 0.415826992743039, #
    #         0.290227047109354, 0.202743599929962, 0.141717713044793
    #     ]
    #     @test output.operation.buffer ≈ expected
    # end

end
