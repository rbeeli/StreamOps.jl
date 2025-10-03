using DataStructures

@testitem "RealtimeIterable(Int, data)" begin
    using Dates

    base_time = StreamOps.time_now(DateTime)
    data = [
        (base_time - Millisecond(500), 1),
        (base_time - Millisecond(600), 2),
        (base_time - Millisecond(800), 3),
    ]

    g = StreamGraph()

    source!(g, :values, RealtimeIterable(Int, data))
    buffer = Buffer{Int}()
    @op g :values => :buffer buffer
    @op g :values => :print Print()

    states = compile_graph!(DateTime, g)
    exe = RealtimeExecutor{DateTime}(g, states)
    setup!(exe)

    start = base_time - Millisecond(1000)
    stop = base_time + Millisecond(1000)

    run!(exe, start, stop)

    @test get_state(buffer) == [1, 2, 3]
end

@testitem "RealtimeIterable(Int, generator)" begin
    using Dates

    base_time = StreamOps.time_now(DateTime)
    generator = ((base_time - Millisecond(100) * x, x) for x in 1:3)

    g = StreamGraph()

    source!(g, :values, RealtimeIterable(DateTime, Int, generator))
    buffer = Buffer{Int}()
    @op g :values => :buffer buffer

    states = compile_graph!(DateTime, g)
    exe = RealtimeExecutor{DateTime}(g, states)
    setup!(exe)

    start = base_time - Millisecond(500)
    stop = base_time + Millisecond(500)

    run!(exe, start, stop)

    @test get_state(buffer) == [1, 2, 3]
end
