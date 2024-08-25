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
        vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
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
        # with pd.option_context('display.float_format', '{:0.12f}'.format):
        #     df = pd.DataFrame({'B': [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]})
        #     print(df.ewm(alpha=0.9, adjust=True).var(bias=False).to_string(index=False))
        # https://github.com/pandas-dev/pandas/blob/main/pandas/_libs/window/aggregations.pyx#L1837
        expected = [
            NaN
            1176.125000000000
             118.379954954955
              14.638763268219
              24.068882923978
           11487.746845379137
          142707.147689443314
        ]
        vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        @test output.operation.buffer ≈ expected rtol=1e-8
    end

end
