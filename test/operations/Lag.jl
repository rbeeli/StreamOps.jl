using Test
using StreamOps

@testset verbose = true "Lag" begin

    @testset "Default lag (lag=1)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        lag_op = op!(g, :lag, Lag{Int}(), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, values, lag_op)
        bind!(g, lag_op, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 5)
            ])
        ])
        run_simulation!(exe, start, stop)
        @test output.operation.buffer == [1, 2, 3, 4]
    end

    @testset "Custom lag (lag=2)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        lag_op = op!(g, :lag, Lag{Int}(2), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, values, lag_op)
        bind!(g, lag_op, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 5)
            ])
        ])
        run_simulation!(exe, start, stop)
        @test output.operation.buffer == [1, 2, 3]
    end

    @testset "Zero lag (lag=0)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        lag_op = op!(g, :lag, Lag{Int}(0), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, values, lag_op)
        bind!(g, lag_op, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 5)
            ])
        ])
        run_simulation!(exe, start, stop)
        @test output.operation.buffer == [1, 2, 3, 4, 5]
    end

    @testset "Invalid lag (negative)" begin
        @test_throws AssertionError Lag{Int}(-1)
    end

end
