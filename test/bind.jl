@testitem "default using symbols" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Print())

    bind!(g, :values, :output)

    @test length(g[:output].input_bindings) == 1
    @test g[:output].input_bindings[1].bind_as isa PositionParams
end

@testitem "default using strings and mixed" begin
    using Dates

    g = StreamGraph()

    source!(g, :values1, out=Float64, init=0.0)
    source!(g, "values2", out=Float64, init=0.0)
    source!(g, "values3", out=Float64, init=0.0)
    sink!(g, :output1, Print())
    sink!(g, "output2", Print())
    sink!(g, "output3", Print())

    bind!(g, :values1, "output1")
    bind!(g, "values2", :output2)
    bind!(g, "values3", "output3")

    display(g[:output1].input_bindings)

    @test length(g[:output1].input_bindings) == 1
    @test length(g["output2"].input_bindings) == 1
    @test length(g[:output3].input_bindings) == 1
    @test g[:output1].input_bindings[1].bind_as isa PositionParams
    @test g[:output2].input_bindings[1].bind_as isa PositionParams
    @test g[:output3].input_bindings[1].bind_as isa PositionParams
end

@testitem "default bind_as=PositionParams" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Print())

    bind!(g, :values, :output)

    @test length(g[:output].input_bindings) == 1
    @test g[:output].input_bindings[1].bind_as isa PositionParams
end

@testitem "single default call_policies=[IfExecuted(:all),IfValid(:all)]" begin
    using Dates

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

@testitem "call_policies=Always()" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Print())

    bind!(g, :values, :output, call_policies=Always())

    @test length(g[:output].input_bindings) == 1
    @test g[:output].input_bindings[1].call_policies[1] isa Always
end

@testitem "call_policies=[Always()]" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Print())

    bind!(g, :values, :output, call_policies=[Always()])

    @test length(g[:output].input_bindings) == 1
    @test g[:output].input_bindings[1].call_policies[1] isa Always
end

@testitem "call_policies=(Always(),)" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Print())

    bind!(g, :values, :output, call_policies=(Always(),))

    @test length(g[:output].input_bindings) == 1
    @test g[:output].input_bindings[1].call_policies[1] isa Always
end

@testitem "multiple default call_policies=[IfExecuted(:all),IfValid(:all)]" begin
    using Dates

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

@testitem "single input using symbol reference" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Print())

    bind!(g, :values, :output)

    @test length(g[:output].input_bindings) == 1
end

@testitem "multiple input using symbol references" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, out=Float64, init=0.0)
    source!(g, :values2, out=Float64, init=0.0)
    sink!(g, :output, Print())

    bind!(g, (:values, :values2), :output)

    @test length(g[:output].input_bindings) == 1
end

@testitem "NamedParams" begin
    using Dates

    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    values = source!(g, :values, out=Float64, init=0.0)

    called = 0
    output = sink!(g, :output, Func((exe; values, timer) -> begin
            global called
            @assert values isa Float64
            @assert timer isa DateTime
            called += 1
        end, nothing))

    bind!(g, (timer, values), output, call_policies=Always(), bind_as=NamedParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, timer; interval=Day(1), start_time=start),
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1.0),
            (DateTime(2000, 1, 2), 2.0),
            (DateTime(2000, 1, 3), 4.0),
        ]),
    ])
    run!(exe, start, stop)

    @test called == 6 # 3 values * 2 sources
end

@testitem "NoBind" begin
    using Dates

    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    values = source!(g, :values, out=Float64, init=0.0)

    called = 0
    output = sink!(g, :output, Func((exe, values) -> begin
            global called
            @assert values isa Float64
            called += 1
        end, nothing))

    bind!(g, timer, output, call_policies=Always(), bind_as=NoBind())
    bind!(g, values, output, call_policies=Always(), bind_as=PositionParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, timer; interval=Day(1), start_time=start),
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1.0),
            (DateTime(2000, 1, 2), 2.0),
            (DateTime(2000, 1, 3), 4.0),
        ]),
    ])
    run!(exe, start, stop)

    @test called == 6 # 3 values * 2 sources
end

@testitem "NamedParams 2x" begin
    using Dates

    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    values = source!(g, :values, out=Float64, init=0.0)
    values2 = source!(g, :values2, out=Float64, init=0.0)
    values3 = source!(g, :values3, out=Float64, init=0.0)

    called = 0
    output = sink!(g, :output, Func((exe; values, timer, values2, values3) -> begin
            global called
            @assert values isa Float64
            @assert timer isa DateTime
            called += 1
        end, nothing))

    bind!(g, (timer, values), output, call_policies=Always(), bind_as=NamedParams())
    bind!(g, (values2, values3), output, call_policies=Always(), bind_as=NamedParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, timer; interval=Day(1), start_time=start),
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
    ])
    run!(exe, start, stop)

    @test called == 12 # 3 values * 4 sources
end

@testitem "PositionParams (default)" begin
    using Dates

    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    values = source!(g, :values, out=Float64, init=0.0)

    called = 0
    output = sink!(g, :output, Func((exe, a, b) -> begin
            global called
            @assert a isa DateTime
            @assert b isa Float64
            called += 1
        end, nothing))

    bind!(g, (timer, values), output, call_policies=Always(), bind_as=PositionParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, timer; interval=Day(1), start_time=start),
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1.0),
            (DateTime(2000, 1, 2), 2.0),
            (DateTime(2000, 1, 3), 4.0),
        ]),
    ])
    run!(exe, start, stop)

    @test called == 6 # 3 values * 2 sources
end

@testitem "TupleParams" begin
    using Dates

    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    values = source!(g, :values, out=Float64, init=0.0)

    called = 0
    output = sink!(g, :output, Func((exe, params) -> begin
            global called
            @assert params isa Tuple{DateTime,Float64}
            called += 1
        end, nothing))

    bind!(g, (timer, values), output, call_policies=Always(), bind_as=TupleParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, timer; interval=Day(1), start_time=start),
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1.0),
            (DateTime(2000, 1, 2), 2.0),
            (DateTime(2000, 1, 3), 4.0),
        ]),
    ])
    run!(exe, start, stop)

    @test called == 6 # 3 values * 2 sources
end

@testitem "TupleParams 2x" begin
    using Dates

    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    values = source!(g, :values, out=Float64, init=0.0)
    values2 = source!(g, :values2, out=Float64, init=0.0)
    values3 = source!(g, :values3, out=Float64, init=0.0)

    called = 0
    output = sink!(g, :output, Func((exe, params, params2) -> begin
            global called
            @assert params isa Tuple{DateTime,Float64}
            called += 1
        end, nothing))

    bind!(g, (timer, values), output, call_policies=Always(), bind_as=TupleParams())
    bind!(g, (values2, values3), output, call_policies=Always(), bind_as=TupleParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, timer; interval=Day(1), start_time=start),
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
    ])
    run!(exe, start, stop)

    @test called == 12 # 3 values * 4 sources
end

@testitem "NamedParams, TupleParams" begin
    using Dates

    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    values = source!(g, :values, out=Float64, init=0.0)
    values2 = source!(g, :values2, out=Float64, init=0.0)
    values3 = source!(g, :values3, out=Float64, init=0.0)

    called = 0
    output = sink!(g, :output, Func((exe, tuple_params; timer, values) -> begin
            global called
            @assert timer isa DateTime
            @assert values isa Float64
            @assert tuple_params isa Tuple{Float64,Float64}
            called += 1
        end, nothing))

    bind!(g, (values2, values3), output, call_policies=Always(), bind_as=TupleParams())
    bind!(g, (timer, values), output, call_policies=Always(), bind_as=NamedParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, timer; interval=Day(1), start_time=start),
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
    ])
    run!(exe, start, stop)

    @test called == 12 # 3 values * 4 sources
end
