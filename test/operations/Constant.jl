using Test
using StreamOps

@testset verbose = true "Constant" begin

    @testset "integer with input binding" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        op!(g, :constant, Constant(999), out=Int)
        sink!(g, :output, Buffer{Int}())

        bind!(g, :values, :constant)
        bind!(g, :constant, :output)

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

        vals = [2, 3, -1, 0, 3]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))

        set_adapters!(exe, [
            HistoricIterable(exe, g[:values], [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])
        run!(exe, start, stop)

        @test g[:output].operation.buffer == [999, 999, 999, 999, 999]
    end

    @testset "integer w/o input binding (source node)" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        op!(g, :constant, Constant(999), out=Int)
        sink!(g, :output, Buffer{Int}())

        bind!(g, :constant, :output)
        bind!(g, :values, :output, bind_as=NoBind())

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

        vals = [2, 3, -1, 0, 3]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        set_adapters!(exe, [
            HistoricIterable(exe, g[:values], [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])
        run!(exe, start, stop)

        @test g[:output].operation.buffer == [999, 999, 999, 999, 999]
    end

    @testset "integer with input trigger but no binding" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        op!(g, :constant, Constant(999), out=Int)
        sink!(g, :output, Buffer{Int}())

        bind!(g, :values, :constant, bind_as=NoBind())
        bind!(g, :constant, :output)

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

        vals = [2, 3, -1, 0, 3]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))

        set_adapters!(exe, [
            HistoricIterable(exe, g[:values], [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])
        run!(exe, start, stop)

        @test g[:output].operation.buffer == [999, 999, 999, 999, 999]
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

    #     states = compile_graph!(DateTime, g)
    #     exe = HistoricExecutor{DateTime}(g, states)
    #     setup!(exe)

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