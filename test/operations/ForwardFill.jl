using Test
using StreamOps

@testset verbose = true "ForwardFill" begin

    @testset "default ctor (missing, NaN filled)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Union{Float64,Missing}, init=NaN)
        ffill = op!(g, :ffill, ForwardFill{Float64}(), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, ffill)
        bind!(g, ffill, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [1.0, NaN, 2.0, -1.0, NaN, NaN, 3.0, NaN, 4.0, missing]
        expected = [1.0, 1.0, 2.0, -1.0, -1.0, -1.0, 3.0, 3.0, 4.0, 4.0]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])

        run!(exe, start, stop)
        @test output.operation.buffer == expected
    end

    @testset "default ctor (missing, NaN filled) w/ string type" begin
        g = StreamGraph()

        values = source!(g, :values, out=Union{String,Missing}, init="")
        ffill = op!(g, :ffill, ForwardFill{String}(), out=String)
        output = sink!(g, :output, Buffer{String}())

        bind!(g, values, ffill)
        bind!(g, ffill, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = ["a", missing, "", "c", missing, missing, "d", missing, "e", missing]
        expected = ["a", "a", "a", "c", "c", "c", "d", "d", "e", "e"]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])

        run!(exe, start, stop)
        @test output.operation.buffer == expected
    end

    @testset "should_fill_fn=<fn>, init=99, first invalid" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        ffill = op!(g, :ffill, ForwardFill{Int}(x -> x == 0, init=99), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, values, ffill)
        bind!(g, ffill, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [0, 1, 3, 0, -2, 4, 3]
        expected = [99, 1, 3, 3, -2, 4, 3]

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])

        run!(exe, start, stop)
        @test output.operation.buffer == expected
    end

end
