@testitem "w/ HistoricIterable" begin
    using Dates

    g = StreamGraph()

    buffer = Float64[]
    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Buffer{Float64}(buffer))
    bind!(g, :values, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 10)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:values], [
            (DateTime(2000, 1, 1), 1.0),
            (DateTime(2000, 1, 2), 2.0),
        ])
    ])
    @time run!(exe, start, stop)

    @test length(buffer) == 2
    @test all(buffer .== [1.0, 2.0])
end

@testitem "w/ HistoricTimer" begin
    using Dates
    
    g = StreamGraph()

    buffer = DateTime[]
    source!(g, :time, out=DateTime, init=DateTime(0))
    sink!(g, :output, Buffer{DateTime}(buffer))
    bind!(g, :time, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 3)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:time], interval=Day(1), start_time=start)
    ])
    @time run!(exe, start, stop)

    @test length(buffer) == 3
    @test all(buffer .== start:Day(1):stop)
end

@testitem "w/ HistoricIterable 2x for 1 source" begin
    using Dates
    
    g = StreamGraph()

    buffer = Float64[]
    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Buffer{Float64}(buffer))
    bind!(g, :values, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 10)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:values], [
            (DateTime(2000, 1, 1), 1.0),
            (DateTime(2000, 1, 2), 2.0),
        ]),
        HistoricIterable(exe, g[:values], [
            (DateTime(2000, 1, 3), 3.0),
            (DateTime(2000, 1, 4), 4.0),
        ])
    ])
    @time run!(exe, start, stop)

    @test length(buffer) == 4
    @test all(buffer .== [1.0, 2.0, 3.0, 4.0])
end

@testitem "source! after op! (out of order)" begin
    using Dates

    g = StreamGraph()

    buffer = Float64[]
    source!(g, :values, out=Float64, init=0.0)
    sink!(g, :output, Buffer{Float64}(buffer))
    bind!(g, :values, :output)

    buffer2 = Float64[]
    source!(g, :values2, out=Float64, init=0.0)
    sink!(g, :output2, Buffer{Float64}(buffer2))
    bind!(g, :values2, :output2)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 10)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:values2], [
            (DateTime(2000, 1, 2), 2.0),
            (DateTime(2000, 1, 4), 4.0),
        ]),
        HistoricIterable(exe, g[:values], [
            (DateTime(2000, 1, 1), 1.0),
            (DateTime(2000, 1, 2), 2.0),
        ])
    ])
    @time run!(exe, start, stop)

    @test length(buffer) == 2
    @test all(buffer .== [1.0, 2.0])

    @test length(buffer2) == 2
    @test all(buffer2 .== [2.0, 4.0])
end
