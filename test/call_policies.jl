@testitem "default policies single input" begin
    using Dates

    g = StreamGraph()

    source!(g, :timer, out=DateTime, init=DateTime(0))

    op!(g, :never_valid, Func((exe, v) -> v, DateTime(0), is_valid=x -> false), out=DateTime)
    bind!(g, :timer, :never_valid)

    sink!(g, :output, Buffer{DateTime}())
    bind!(g, :never_valid, :output)

    # check default call policies
    @test length(g[:output].input_bindings[1].call_policies) == 2
    @test g[:output].input_bindings[1].call_policies[1] isa IfExecuted
    @test g[:output].input_bindings[1].call_policies[2] isa IfValid
end

@testitem "default policies multi-input" begin
    using Dates

    g = StreamGraph()

    source!(g, :timer, out=DateTime, init=DateTime(0))

    op!(g, :never_valid, Func((exe, v) -> v, DateTime(0), is_valid=x -> false), out=DateTime)
    bind!(g, :timer, :never_valid)

    sink!(g, :output, Buffer{Tuple{DateTime,DateTime}}())
    bind!(g, (:timer, :never_valid), :output, bind_as=TupleParams())

    # check default call policies
    @test length(g[:output].input_bindings[1].call_policies) == 2
    @test g[:output].input_bindings[1].call_policies[1] isa IfExecuted
    @test g[:output].input_bindings[1].call_policies[2] isa IfValid
end

@testitem "IfValid (never valid)" begin
    using Dates

    g = StreamGraph()

    source!(g, :timer, out=DateTime, init=DateTime(0))

    op!(g, :never_valid, Func((exe, v) -> v, DateTime(0), is_valid=x -> false), out=DateTime)
    bind!(g, :timer, :never_valid)

    sink!(g, :output, Buffer{DateTime}())
    bind!(g, :never_valid, :output, call_policies=IfValid(:all))

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer]; interval=Day(1), start_time=start)
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    @test length(buffer) == 0
end

@testitem "IfValid(:a, :b)" begin
    using Dates

    g = StreamGraph()

    source!(g, :a, out=Union{Nothing,Int}, init=nothing)
    source!(g, :b, out=Union{Nothing,Int}, init=nothing)

    sink!(g, :output, Buffer{NTuple{2,Int}}())
    bind!(g, (:a, :b), :output, call_policies=IfValid(:a, :b), bind_as=TupleParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:a], [
            (DateTime(2000, 1, 1), nothing),
            (DateTime(2000, 1, 2), nothing),
            (DateTime(2000, 1, 3), nothing),
            (DateTime(2000, 1, 4), 4)
        ])
        HistoricIterable(exe, g[:b], [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), nothing),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ])
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    @test length(buffer) == 2
    @test buffer[1] == (4, 3)
    @test buffer[2] == (4, 4)
end

@testitem "IfValid(:all)" begin
    using Dates

    g = StreamGraph()

    source!(g, :a, out=Union{Nothing,Int}, init=nothing)
    source!(g, :b, out=Union{Nothing,Int}, init=nothing)

    sink!(g, :output, Buffer{NTuple{2,Int}}())
    bind!(g, (:a, :b), :output, call_policies=IfValid(:all), bind_as=TupleParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:a], [
            (DateTime(2000, 1, 1), nothing),
            (DateTime(2000, 1, 2), nothing),
            (DateTime(2000, 1, 3), nothing),
            (DateTime(2000, 1, 4), 4)
        ])
        HistoricIterable(exe, g[:b], [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), nothing),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ])
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    @test length(buffer) == 2
    @test buffer[1] == (4, 3)
    @test buffer[2] == (4, 4)
end

@testitem "IfValid(:any)" begin
    using Dates

    g = StreamGraph()

    source!(g, :a, out=Union{Nothing,Int}, init=nothing)
    source!(g, :b, out=Union{Nothing,Int}, init=nothing)

    sink!(g, :output, Buffer{NTuple{2,Union{Nothing,Int}}}())
    bind!(g, (:a, :b), :output, call_policies=IfValid(:any), bind_as=TupleParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:a], [
            (DateTime(2000, 1, 1), nothing),
            (DateTime(2000, 1, 2), nothing),
            (DateTime(2000, 1, 3), nothing),
            (DateTime(2000, 1, 4), 4)
        ])
        HistoricIterable(exe, g[:b], [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), nothing),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ])
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    
    @test length(buffer) == 5
    @test buffer[1] == (nothing, 1)
    @test buffer[2] == (nothing, 1)
    @test buffer[3] == (nothing, 3)
    @test buffer[4] == (4, 3)
    @test buffer[5] == (4, 4)
end

@testitem "IfInvalid (never valid)" begin
    using Dates

    g = StreamGraph()

    source!(g, :timer, out=DateTime, init=DateTime(0))

    op!(g, :never_valid, Func((exe, v) -> NaN, NaN, is_valid=x -> false), out=Float64)
    bind!(g, :timer, :never_valid)

    sink!(g, :output, Buffer{Float64}())
    bind!(g, :never_valid, :output, call_policies=IfInvalid())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer]; interval=Day(1), start_time=start)
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    
    @test length(buffer) == 3
    @test all(isnan.(buffer))
end

@testitem "IfSource(:timer1)" begin
    using Dates

    g = StreamGraph()

    source!(g, :timer1, out=DateTime, init=DateTime(0))
    source!(g, :timer2, out=DateTime, init=DateTime(0))

    op!(g, :call_if_1, Func((exe, dt1, dt2) -> (dt1, dt2), (DateTime(0), DateTime(0))), out=NTuple{2,DateTime})
    bind!(g, (:timer1, :timer2), :call_if_1, call_policies=IfSource(:timer1))

    sink!(g, :output, Buffer{NTuple{2,DateTime}}())
    bind!(g, :call_if_1, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer1]; interval=Day(1), start_time=start),
        HistoricTimer{DateTime}(exe, g[:timer2]; interval=Hour(6), start_time=start)
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    
    @test length(buffer) == 3
end

@testitem "IfSource('timer1')" begin
    using Dates

    g = StreamGraph()

    source!(g, :timer1, out=DateTime, init=DateTime(0))
    source!(g, :timer2, out=DateTime, init=DateTime(0))

    op!(g, :call_if_1, Func((exe, dt1, dt2) -> (dt1, dt2), (DateTime(0), DateTime(0))), out=NTuple{2,DateTime})
    bind!(g, (:timer1, :timer2), :call_if_1, call_policies=IfSource("timer1"))

    sink!(g, :output, Buffer{NTuple{2,DateTime}}())
    bind!(g, :call_if_1, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer1]; interval=Day(1), start_time=start),
        HistoricTimer{DateTime}(exe, g[:timer2]; interval=Hour(6), start_time=start)
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    
    @test length(buffer) == 3
end

@testitem "IfExecuted(:any)" begin
    using Dates

    g = StreamGraph()

    source!(g, :vals1, out=Float64, init=0.0)
    source!(g, :vals2, out=Float64, init=0.0)

    op!(g, :call_any, Func((exe) -> time(exe), DateTime(0)), out=DateTime)
    bind!(g, (:vals1, :vals2), :call_any, bind_as=NoBind(), call_policies=IfExecuted(:any))

    sink!(g, :output, Buffer{DateTime}())
    bind!(g, :call_any, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 2)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:vals1], [
            (DateTime("2000-01-01T00:00:10"), 10.0),
            (DateTime("2000-01-01T00:01:00"), 100.0),
            (DateTime("2000-01-01T00:03:00"), 300.0),
        ]),
        HistoricIterable(exe, g[:vals2], [
            (DateTime("2000-01-01T00:00:00"), 0.0),
            (DateTime("2000-01-01T00:01:00"), 100.0),
            (DateTime("2000-01-01T00:02:00"), 200.0),
            (DateTime("2000-01-01T00:03:00"), 300.0),
            (DateTime("2000-01-01T00:08:00"), 800.0),
        ])
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer

    @test all(buffer .== [
        DateTime("2000-01-01T00:00:00"),
        DateTime("2000-01-01T00:00:10"),
        DateTime("2000-01-01T00:01:00"),
        DateTime("2000-01-01T00:01:00"),
        DateTime("2000-01-01T00:02:00"),
        DateTime("2000-01-01T00:03:00"),
        DateTime("2000-01-01T00:03:00"),
        DateTime("2000-01-01T00:08:00"),
    ])
end

# @testitem "IfNotExecuted()" begin
#     using Dates

#     g = StreamGraph()

#     source!(g, :a, out=Int, init=0)
#     source!(g, :b, out=Int, init=0)

#     op!(g, :call_if_1, Func((exe, _) -> time(exe), DateTime(0)), out=DateTime)
#     bind!(g, :a, :call_if_1, call_policies=IfNotExecuted())

#     sink!(g, :output, Buffer{DateTime}())
#     bind!(g, :call_if_1, :output)

#     states = compile_graph!(DateTime, g)
#     exe = HistoricExecutor{DateTime}(g, states)
#     setup!(exe)

#     start = DateTime(2000, 1, 1)
#     stop = DateTime(2000, 1, 4)
#     set_adapters!(exe, [
#         HistoricIterable(exe, g[:a], [
#             (DateTime(2000, 1, 4), 4)
#         ])
#         HistoricIterable(exe, g[:b], [
#             (DateTime(2000, 1, 1), 1),
#             (DateTime(2000, 1, 2), 2),
#             (DateTime(2000, 1, 3), 3),
#             (DateTime(2000, 1, 4), 4)
#         ])
#     ])
#     run!(exe, start, stop)

#     buffer = g[:output].operation.buffer
#     display(buffer)

#     # @test length(buffer) == 12
# end

@testitem "IfExecuted(:timer1)" begin
    using Dates
    
    g = StreamGraph()

    source!(g, :timer1, out=DateTime, init=DateTime(0))
    source!(g, :timer2, out=DateTime, init=DateTime(0))

    op!(g, :call_if_1, Func((exe, dt1, dt2) -> (dt1, dt2), (DateTime(0), DateTime(0))), out=NTuple{2,DateTime})
    bind!(g, (:timer1, :timer2), :call_if_1, call_policies=IfExecuted(:timer1))

    sink!(g, :output, Buffer{NTuple{2,DateTime}}())
    bind!(g, :call_if_1, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer1]; interval=Day(1), start_time=start),
        HistoricTimer{DateTime}(exe, g[:timer2]; interval=Hour(6), start_time=start)
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    
    @test length(buffer) == 3
end

@testitem "IfExecuted('timer1')" begin
    using Dates
    
    g = StreamGraph()

    source!(g, :timer1, out=DateTime, init=DateTime(0))
    source!(g, :timer2, out=DateTime, init=DateTime(0))

    op!(g, :call_if_1, Func((exe, dt1, dt2) -> (dt1, dt2), (DateTime(0), DateTime(0))), out=NTuple{2,DateTime})
    bind!(g, (:timer1, :timer2), :call_if_1, call_policies=IfExecuted("timer1"))

    sink!(g, :output, Buffer{NTuple{2,DateTime}}())
    bind!(g, :call_if_1, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer1]; interval=Day(1), start_time=start),
        HistoricTimer{DateTime}(exe, g[:timer2]; interval=Hour(6), start_time=start)
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    
    @test length(buffer) == 3
end

@testitem "IfExecuted order verification - valid cases" begin
    using Dates
    using Test
    
    # Test case 1: Valid specific node reference
    g = StreamGraph()
    source!(g, :source, out=Int, init=0)
    op!(g, :a, Func((exe, x) -> x + 1, 0), out=Int)
    op!(g, :b, Func((exe, x) -> x * 2, 0), out=Int)
    bind!(g, :source, :a)
    bind!(g, :a, :b, call_policies=IfExecuted(:a))
    @test_nowarn compile_graph!(DateTime, g)

    # Test case 2: Valid :any/:all with input nodes
    g = StreamGraph()
    source!(g, :source1, out=Int, init=0)
    source!(g, :source2, out=Int, init=0)
    op!(g, :target, Func((exe, x, y) -> x + y, 0), out=Int)
    bind!(g, (:source1, :source2), :target, call_policies=IfExecuted(:any))
    @test_nowarn compile_graph!(DateTime, g)
end

@testitem "IfExecuted order verification - invalid cases" begin
    using Dates
    using Test
    
    # Test case 1: Invalid specific node reference (b depends on c which comes after)
    g = StreamGraph()
    source!(g, :source, out=Int, init=0)
    op!(g, :a, Func((exe, x) -> x + 1, 0), out=Int)
    op!(g, :b, Func((exe, x) -> x * 2, 0), out=Int)
    op!(g, :c, Func((exe, x) -> x * 3, 0), out=Int)
    bind!(g, :source, :a)
    bind!(g, :a, :c)
    bind!(g, :a, :b, call_policies=IfExecuted(:c))
    @test_throws "Invalid IfExecuted policy in node [b]: referenced node [c] comes after the node in topological order" compile_graph!(DateTime, g)

    # Test case 2: Invalid :any/:all case (target depends on source2 which comes after in topo order)
    g = StreamGraph()
    source!(g, :source1, out=Int, init=0)
    op!(g, :target, Func((exe, x) -> x * 2, 0), out=Int)
    source!(g, :source2, out=Int, init=0)
    bind!(g, :source1, :target)
    bind!(g, :source2, :target, call_policies=IfExecuted(:any))
    @test_throws "Invalid IfExecuted policy in node [target]: referenced node [source2] comes after the node in topological order" compile_graph!(DateTime, g)
end
