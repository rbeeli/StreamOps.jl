using DataStructures

@testitem "RealtimeTimer(DateTime, Millisecond)" begin
    using Dates

    base_time = StreamOps.time_now(DateTime)
    interval = Millisecond(50)
    start = base_time
    stop = base_time + Millisecond(800)

    g = StreamGraph()

    ticks = source!(
        g,
        :ticks,
        RealtimeTimer(; interval=interval, start_time=start, stop_check_interval=Millisecond(1)),
    )
    buffer = Buffer{DateTime}()
    sink!(g, :buffer, buffer)

    bind!(g, :ticks, :buffer)

    states = compile_graph!(DateTime, g)
    exe = RealtimeExecutor{DateTime}(g, states)
    setup!(exe)

    run!(exe, start, stop)

    values = get_state(buffer)
    @test !isempty(values)
    @test issorted(values)
    @test all(start <= t <= stop for t in values)
end
