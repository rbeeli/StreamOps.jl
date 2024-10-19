using Test
using Dates
using StreamOps

@testset verbose = true "bind! input nodes" begin

    @testset "default bind_as=PositionParams" begin
        g = StreamGraph()

        source!(g, :values, out=Float64, init=0.0)
        sink!(g, :output, Print())

        bind!(g, :values, :output)

        @test length(g[:output].input_bindings) == 1
        @test g[:output].input_bindings[1].bind_as isa PositionParams
    end

    @testset "single default call_policies=[IfExecuted(:all),IfValid(:all)]" begin
        g = StreamGraph()

        source!(g, :values, out=Float64, init=0.0)
        sink!(g, :output, Print())

        bind!(g, :values, :output)

        @test length(g[:output].input_bindings) == 1
        @test g[:output].input_bindings[1].call_policies[1] isa IfExecuted
        @test g[:output].input_bindings[1].call_policies[1].nodes == :any
        @test g[:output].input_bindings[1].call_policies[2] isa IfValid
        @test g[:output].input_bindings[1].call_policies[2].nodes == :all
    end

    @testset "call_policies=Always()" begin
        g = StreamGraph()

        source!(g, :values, out=Float64, init=0.0)
        sink!(g, :output, Print())

        bind!(g, :values, :output, call_policies=Always())

        @test length(g[:output].input_bindings) == 1
        @test g[:output].input_bindings[1].call_policies[1] isa Always
    end

    @testset "call_policies=[Always()]" begin
        g = StreamGraph()

        source!(g, :values, out=Float64, init=0.0)
        sink!(g, :output, Print())

        bind!(g, :values, :output, call_policies=[Always()])

        @test length(g[:output].input_bindings) == 1
        @test g[:output].input_bindings[1].call_policies[1] isa Always
    end

    @testset "call_policies=(Always(),)" begin
        g = StreamGraph()

        source!(g, :values, out=Float64, init=0.0)
        sink!(g, :output, Print())

        bind!(g, :values, :output, call_policies=(Always(),))

        @test length(g[:output].input_bindings) == 1
        @test g[:output].input_bindings[1].call_policies[1] isa Always
    end

    @testset "multiple default call_policies=[IfExecuted(:all),IfValid(:all)]" begin
        g = StreamGraph()

        source!(g, :values, out=Float64, init=0.0)
        source!(g, :values2, out=Float64, init=0.0)
        sink!(g, :output, Print())

        bind!(g, (:values, :values2), :output)

        @test length(g[:output].input_bindings) == 1
        @test g[:output].input_bindings[1].call_policies[1] isa IfExecuted
        @test g[:output].input_bindings[1].call_policies[1].nodes == :any
        @test g[:output].input_bindings[1].call_policies[2] isa IfValid
        @test g[:output].input_bindings[1].call_policies[2].nodes == :all
    end

    @testset "single input using symbol reference" begin
        g = StreamGraph()

        source!(g, :values, out=Float64, init=0.0)
        sink!(g, :output, Print())

        bind!(g, :values, :output)

        @test length(g[:output].input_bindings) == 1
    end

    @testset "multiple input using symbol references" begin
        g = StreamGraph()

        source!(g, :values, out=Float64, init=0.0)
        source!(g, :values2, out=Float64, init=0.0)
        sink!(g, :output, Print())

        bind!(g, (:values, :values2), :output)

        @test length(g[:output].input_bindings) == 1
    end

    @testset "NamedParams" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe; values, timer) -> begin
                @assert values isa Float64
                @assert timer isa DateTime
                called += 1
            end, nothing))

        bind!(g, (timer, values), output, call_policies=Always(), bind_as=NamedParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            HistoricTimer{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 6 # 3 values * 2 sources
    end

    @testset "NoBind" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe, values) -> begin
                @assert values isa Float64
                called += 1
            end, nothing))

        bind!(g, timer, output, call_policies=Always(), bind_as=NoBind())
        bind!(g, values, output, call_policies=Always(), bind_as=PositionParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            HistoricTimer{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 6 # 3 values * 2 sources
    end

    @testset "NamedParams 2x" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)
        values2 = source!(g, :values2, out=Float64, init=0.0)
        values3 = source!(g, :values3, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe; values, timer, values2, values3) -> begin
                @assert values isa Float64
                @assert timer isa DateTime
                called += 1
            end, nothing))

        bind!(g, (timer, values), output, call_policies=Always(), bind_as=NamedParams())
        bind!(g, (values2, values3), output, call_policies=Always(), bind_as=NamedParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            HistoricTimer{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
            HistoricIterable(exe, values2, [
                (DateTime(2000, 1, 1), -1.0),
                (DateTime(2000, 1, 2), -2.0),
                (DateTime(2000, 1, 3), -4.0),
            ]),
            HistoricIterable(exe, values3, [
                (DateTime(2000, 1, 1), 10.0),
                (DateTime(2000, 1, 2), 20.0),
                (DateTime(2000, 1, 3), 40.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 12 # 3 values * 4 sources
    end

    @testset "PositionParams (default)" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe, a, b) -> begin
                @assert a isa DateTime
                @assert b isa Float64
                called += 1
            end, nothing))

        bind!(g, (timer, values), output, call_policies=Always(), bind_as=PositionParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            HistoricTimer{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 6 # 3 values * 2 sources
    end

    @testset "TupleParams" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe, params) -> begin
                @assert params isa Tuple{DateTime,Float64}
                called += 1
            end, nothing))

        bind!(g, (timer, values), output, call_policies=Always(), bind_as=TupleParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            HistoricTimer{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 6 # 3 values * 2 sources
    end

    @testset "TupleParams 2x" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)
        values2 = source!(g, :values2, out=Float64, init=0.0)
        values3 = source!(g, :values3, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe, params, params2) -> begin
                @assert params isa Tuple{DateTime,Float64}
                called += 1
            end, nothing))

        bind!(g, (timer, values), output, call_policies=Always(), bind_as=TupleParams())
        bind!(g, (values2, values3), output, call_policies=Always(), bind_as=TupleParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            HistoricTimer{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
            HistoricIterable(exe, values2, [
                (DateTime(2000, 1, 1), -1.0),
                (DateTime(2000, 1, 2), -2.0),
                (DateTime(2000, 1, 3), -4.0),
            ]),
            HistoricIterable(exe, values3, [
                (DateTime(2000, 1, 1), 10.0),
                (DateTime(2000, 1, 2), 20.0),
                (DateTime(2000, 1, 3), 40.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 12 # 3 values * 4 sources
    end

    @testset "NamedParams, TupleParams" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)
        values2 = source!(g, :values2, out=Float64, init=0.0)
        values3 = source!(g, :values3, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe, tuple_params; timer, values) -> begin
                @assert timer isa DateTime
                @assert values isa Float64
                @assert tuple_params isa Tuple{Float64,Float64}
                called += 1
            end, nothing))

        bind!(g, (values2, values3), output, call_policies=Always(), bind_as=TupleParams())
        bind!(g, (timer, values), output, call_policies=Always(), bind_as=NamedParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            HistoricTimer{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
            HistoricIterable(exe, values2, [
                (DateTime(2000, 1, 1), -1.0),
                (DateTime(2000, 1, 2), -2.0),
                (DateTime(2000, 1, 3), -4.0),
            ]),
            HistoricIterable(exe, values3, [
                (DateTime(2000, 1, 1), 10.0),
                (DateTime(2000, 1, 2), 20.0),
                (DateTime(2000, 1, 3), 40.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 12 # 3 values * 4 sources
    end

end
