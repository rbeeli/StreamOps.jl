@testitem "HistoricIterable" begin
    using Dates

    g = StreamGraph()

    buffer = Float64[]
    values_data = [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
    ]
    source!(g, :values, HistoricIterable(Float64, values_data))
    sink!(g, :output, Buffer{Float64}(buffer))
    bind!(g, :values, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 10)
    @time run!(exe, start, stop)

    @test length(buffer) == 2
    @test all(buffer .== [1.0, 2.0])
end

@testitem "HistoricIterable w/ drop_events_before_start" begin
    using Dates

    g = StreamGraph()

    buffer = Float64[]
    values_data = [
        (DateTime(1999, 12, 31), 0.0),
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
    ]
    source!(g, :values, HistoricIterable(Float64, values_data))
    sink!(g, :output, Buffer{Float64}(buffer))
    bind!(g, :values, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states, drop_events_before_start=true)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 10)
    @time run!(exe, start, stop)

    @test length(buffer) == 2
    @test all(buffer .== [1.0, 2.0])
end

@testitem "HistoricTimer" begin
    using Dates
    
    g = StreamGraph()

    buffer = DateTime[]
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)

    source!(g, :time, HistoricTimer(interval=Day(1), start_time=start))
    sink!(g, :output, Buffer{DateTime}(buffer))
    bind!(g, :time, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    @time run!(exe, start, stop)

    @test length(buffer) == 3
    @test all(buffer .== start:Day(1):stop)
end

@testitem "HistoricIterable 2x for 1 source" begin
    using Dates
    
    g = StreamGraph()

    buffer = Float64[]
    values_data = [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
        (DateTime(2000, 1, 4), 4.0),
    ]
    source!(g, :values, HistoricIterable(Float64, values_data))
    sink!(g, :output, Buffer{Float64}(buffer))
    bind!(g, :values, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 10)
    @time run!(exe, start, stop)

    @test length(buffer) == 4
    @test all(buffer .== [1.0, 2.0, 3.0, 4.0])
end

@testitem "source! after op! (out of order)" begin
    using Dates

    g = StreamGraph()

    buffer = Float64[]
    values_data = [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
    ]
    source!(g, :values, HistoricIterable(Float64, values_data))
    sink!(g, :output, Buffer{Float64}(buffer))
    bind!(g, :values, :output)

    buffer2 = Float64[]
    values2_data = [
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 4), 4.0),
    ]
    source!(g, :values2, HistoricIterable(Float64, values2_data))
    sink!(g, :output2, Buffer{Float64}(buffer2))
    bind!(g, :values2, :output2)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 10)
    @time run!(exe, start, stop)

    @test length(buffer) == 2
    @test all(buffer .== [1.0, 2.0])

    @test length(buffer2) == 2
    @test all(buffer2 .== [2.0, 4.0])
end

@testitem "HistoricIterable reset!" begin
    using Dates

    g = StreamGraph()

    buffer = Float64[]
    values_data = [
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
    ]
    source!(g, :values, HistoricIterable(Float64, values_data))
    sink!(g, :output, Buffer{Float64}(buffer))
    bind!(g, :values, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    adapter = exe.source_adapters[1]

    run!(exe, start, stop)
    @test buffer == [1.0, 2.0, 3.0]

    reset!(adapter)
    empty!(buffer)

    run!(exe, start, stop)
    @test buffer == [1.0, 2.0, 3.0]
end

@testitem "HistoricTimer reset!" begin
    using Dates

    g = StreamGraph()

    buffer = DateTime[]
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    source!(g, :time, HistoricTimer(interval=Day(1), start_time=start))
    sink!(g, :output, Buffer{DateTime}(buffer))
    bind!(g, :time, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    adapter = exe.source_adapters[1]

    run!(exe, start, stop)
    @test buffer == collect(start:Day(1):stop)
    @test adapter.current_time == stop + Day(1)

    reset!(adapter)
    empty!(buffer)
    @test adapter.current_time == adapter.start_time == start

    run!(exe, start, stop)
    @test buffer == collect(start:Day(1):stop)
end
