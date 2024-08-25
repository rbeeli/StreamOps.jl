using Test
using StreamOps
using Statistics

@testset verbose = true "ZScore" begin

    @testset "window_size=5 corrected=true(default)" begin
        window_size = 5

        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        zscore = op!(g, :zscore, ZScore{Float64,Float64}(window_size), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, zscore)
        bind!(g, zscore, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        expected = [-0.9203579866168446, -0.35082320772281156,
            0.35082320772281156, 0.9203579866168446, -0.9203579866168446, -0.35082320772281156]
        @test output.operation.buffer ≈ expected
    end

    @testset "window_size=3 corrected=false" begin
        window_size = 3

        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        zscore = op!(g, :zscore, ZScore{Float64,Float64}(window_size, corrected=false), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, zscore)
        bind!(g, zscore, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        expected = [1.224744871391589, 1.224744871391589, -1.3363062095621219, -0.2672612419124245,
            1.224744871391589, 1.224744871391589, -1.3363062095621219, -0.2672612419124245]
        @test output.operation.buffer ≈ expected
    end

    @testset "Edge case: Single value" begin
        window_size = 1
        g = StreamGraph()
        values = source!(g, :values, out=Float64, init=0.0)
        zscore = op!(g, :zscore, ZScore{Float64,Float64}(window_size), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())
        bind!(g, values, zscore)
        bind!(g, zscore, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        adapters = [IterableAdapter(exe, values, [(DateTime(2000, 1, 1), 1.0)])]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 1)
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        # Z-score should be NaN for single value
        @test isnan(output.operation.buffer[1])
        @test length(output.operation.buffer) == 1
    end

    @testset "Edge case: Constant values" begin
        window_size = 5
        g = StreamGraph()
        values = source!(g, :values, out=Float64, init=0.0)
        zscore = op!(g, :zscore, ZScore{Float64,Float64}(window_size), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())
        bind!(g, values, zscore)
        bind!(g, zscore, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        constant_vals = [2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(constant_vals)
            ])
        ]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(constant_vals))
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        for i in eachindex(output.operation.buffer)
            # Z-score should be NaN for constant values (std dev = 0)
            @test isnan(output.operation.buffer[i])
        end
    end

end