using DataStructures

@testitem "HistoricTimer(DateTime, Day)" begin
    using Dates

    timer_start = DateTime(2000, 1, 1)
    g = StreamGraph()

    source!(g, :ticks, HistoricTimer(; interval=Day(1), start_time=timer_start))
    buffer = Buffer{DateTime}()
    sink!(g, :buffer, buffer)

    @bind g :ticks => :buffer

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    run!(exe, timer_start, timer_start + Day(2))

    @test get_state(buffer) == [timer_start, timer_start + Day(1), timer_start + Day(2)]
end
