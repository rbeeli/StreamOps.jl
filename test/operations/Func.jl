using Test
using StreamOps

@testset verbose = true "Func" begin

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
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])
        run!(exe, start, stop)

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
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])
        run!(exe, start, stop)

        @test output.operation.buffer == [4, 9, 1, 0, 9]
    end

    @testset "Func(func) (Nothing output type)" begin
        g = StreamGraph()

        function do_nothing()
        end

        values = source!(g, :values, out=Int, init=0)
        buffer = op!(g, :buffer, Func((exe, x) -> do_nothing(), nothing), out=Nothing)
        output = sink!(g, :output, Buffer{Nothing}())

        bind!(g, values, buffer)
        bind!(g, buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 2)
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2)
            ])
        ])
        run!(exe, start, stop)

        @test is_valid(buffer.operation)

        @test all(isnothing.(output.operation.buffer))
    end

    @testset "Func{T}(func, init::T, is_valid)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = op!(g, :buffer, Func{Int}((exe, x) -> x, 0, is_valid=v -> v > 0), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, values, buffer)
        bind!(g, buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [2, 3, -1, 0, 3]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])
        run!(exe, start, stop)

        @test output.operation.buffer == [2, 3, 3]
    end

end
