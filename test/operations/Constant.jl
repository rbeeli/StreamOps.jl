using Test
using StreamOps

@testset verbose = true "Constant" begin

    @testset "integer with input binding" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        constant = op!(g, :constant, Constant(999), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, values, constant)
        bind!(g, constant, output)

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

        @test output.operation.buffer == [999, 999, 999, 999, 999]
    end

    @testset "integer w/o input binding (source node)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        constant = op!(g, :constant, Constant(999), out=Int)
        output = sink!(g, :output, Buffer{Int}())

        bind!(g, constant, output)
        bind!(g, values, output, bind_as=NoBind())

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

        @test output.operation.buffer == [999, 999, 999, 999, 999]
    end

    # @testset "constant as invalid fallback value" begin
    #     g = StreamGraph()

    #     values = source!(g, :values, out=Int, init=0)
    #     constant = op!(g, :constant, Constant(9.9), out=Float64)
    #     mean = op!(g, :mean, Mean{Int,Float64}(3; full_only=true), out=Float64) # only valid with 3+ values
    #     output = sink!(g, :output, Buffer{Float64}())

    #     bind!(g, values, mean)
    #     bind!(g, mean, output)
    #     bind!(g, constant, output, call_policies=IfInvalid(:mean))

    #     exe = compile_historic_executor(DateTime, g; debug=!true)

    #     vals = [2, 3, -1, 0, 3]
    #     start = DateTime(2000, 1, 1)
    #     stop = DateTime(2000, 1, length(vals))
    #     set_adapters!(exe, [
    #         HistoricIterable(exe, values, [
    #             (DateTime(2000, 1, i), x)
    #             for (i, x) in enumerate(vals)
    #         ])
    #     ])
    #     run!(exe, start, stop)

    #     println(output.operation.buffer)
    #     # @test output.operation.buffer == [999, 999, 999, 999, 999]
    # end

end