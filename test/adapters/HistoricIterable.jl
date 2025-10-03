using DataStructures

@testitem "list" begin
    using Dates

    data = [(DateTime(2000, 1, 1), 1), (DateTime(2000, 1, 2), 2), (DateTime(2000, 1, 3), 3)]

    g = StreamGraph()

    source!(g, :values, HistoricIterable(Int, data))
    buffer = Buffer{Int}()
    @sink g :values => :buffer buffer

    @test buffer.min_count == 0

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    adapter = exe.source_adapters[1]

    # first event is scheduled
    setup!(adapter, exe)

    @test length(exe.event_queue) == 1
    evt = pop!(exe.event_queue)
    @test evt.timestamp == DateTime(2000, 1, 1)

    # second event is executed
    advance!(adapter, exe)

    @test length(exe.event_queue) == 1
    evt = pop!(exe.event_queue)
    @test evt.timestamp == DateTime(2000, 1, 2)

    # third event is executed
    advance!(adapter, exe)

    @test length(exe.event_queue) == 1
    evt = pop!(exe.event_queue)
    @test evt.timestamp == DateTime(2000, 1, 3)

    # no more events
    advance!(adapter, exe)

    @test length(exe.event_queue) == 0
end

@testitem "generator" begin
    using Dates

    generator = ((DateTime(2000, 1, x), x) for x in 1:3)

    g = StreamGraph()

    source!(g, :values, HistoricIterable(DateTime, Int, generator))
    buffer = Buffer{Int}()
    @sink g :values => :buffer buffer

    @test buffer.min_count == 0

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    adapter = exe.source_adapters[1]

    # first event is scheduled
    setup!(adapter, exe)

    @test length(exe.event_queue) == 1
    evt = pop!(exe.event_queue)
    @test evt.timestamp == DateTime(2000, 1, 1)

    # second event is executed
    advance!(adapter, exe)

    @test length(exe.event_queue) == 1
    evt = pop!(exe.event_queue)
    @test evt.timestamp == DateTime(2000, 1, 2)

    # third event is executed
    advance!(adapter, exe)

    @test length(exe.event_queue) == 1
    evt = pop!(exe.event_queue)
    @test evt.timestamp == DateTime(2000, 1, 3)

    # no more events
    advance!(adapter, exe)

    @test length(exe.event_queue) == 0
end
