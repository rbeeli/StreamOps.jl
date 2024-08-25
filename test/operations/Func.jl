using Test
using StreamOps

@testset "Func" begin

    @testset "Func(func, init)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = op!(g, :buffer, Func((exe, x) -> x^2, 0), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, values, buffer)
        bind!(g, buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [2, 3, -1, 0, 3]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        @test output.operation.buffer == [4, 9, 1, 0, 9]
    end

    @testset "Func{T}(func, init::T)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = op!(g, :buffer, Func{Int}((exe, x) -> x^2, 0), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, values, buffer)
        bind!(g, buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [2, 3, -1, 0, 3]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        @test output.operation.buffer == [4, 9, 1, 0, 9]
    end

    @testset "Func(func) (Nothing output type)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = op!(g, :buffer, Func{Int}((exe, x) -> x^2, 0), out=Nothing)
        output = sink!(g, :output, Buffer{Nothing}())

        bind!(g, values, buffer)
        bind!(g, buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [2, 3, -1, 0, 3]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)

        @test all(isnothing.(output.operation.buffer))
    end

end
