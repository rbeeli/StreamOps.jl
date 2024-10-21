using DataStructures

@testitem "default" begin
    using Dates

    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    buffer = sink!(g, :buffer, Buffer{Int}())

    @test buffer.operation.min_count == 0

    bind!(g, values, buffer)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    adapter = HistoricIterable(exe, values, [
        (DateTime(2000, 1, 1), 1),
        (DateTime(2000, 1, 2), 2),
        (DateTime(2000, 1, 3), 3)
    ])

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
