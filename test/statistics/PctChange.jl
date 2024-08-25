using Test
using StreamOps

@testset verbose = true "PctChange" begin

    @testset "window_size=2 (default)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        pct_buffer = op!(g, :pct_buffer, WindowBuffer{Int}(2, init_value=0), out=AbstractVector{Int})
        pct_change = op!(g, :pct_change, PctChange{Int,Float64}(), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, pct_buffer)
        bind!(g, pct_buffer, pct_change)
        bind!(g, pct_change, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 1)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)
        @test output.operation.buffer ≈ [1.0, 0.5, 0.3333333333333333, -0.75]
    end

    @testset "window_size=2 <Always>" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        pct_buffer = op!(g, :pct_buffer, WindowBuffer{Int}(2, init_value=0), out=AbstractVector{Int})
        pct_change = op!(g, :pct_change, PctChange{Int,Float64}(), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, pct_buffer)
        bind!(g, pct_buffer, pct_change, call_policies=[Always()])
        bind!(g, pct_change, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 1)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)
        @test output.operation.buffer ≈ [Inf, 1.0, 0.5, 0.3333333333333333, -0.75]
    end

    @testset "window_size=3" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        pct_buffer = op!(g, :pct_buffer, WindowBuffer{Int}(3, init_value=0), out=AbstractVector{Int})
        pct_change = op!(g, :pct_change, PctChange{Int,Float64}(), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, pct_buffer)
        bind!(g, pct_buffer, pct_change)
        bind!(g, pct_change, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 1)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)
        @test output.operation.buffer ≈ [3 / 1 - 1, 4 / 2 - 1, 1 / 3 - 1]
    end

end
