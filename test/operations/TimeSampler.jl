@testitem "sample every minute" begin
    using Dates
    
    g = StreamGraph()

    source!(g, :values, out=Int, init=0)

    op!(g, :sampler, TimeSampler{DateTime,Int}(Minute(1)), out=Int)
    bind!(g, :values, :sampler)

    @test !is_valid(g[:sampler].operation)

    op!(g, :timestamper, Func{Tuple{DateTime,Int}}((exe, x) -> (time(exe), x), (DateTime(0), 0)), out=Tuple{DateTime,Int})
    bind!(g, :sampler, :timestamper)

    output = sink!(g, :output, Buffer{Tuple{DateTime,Int}}())
    bind!(g, :timestamper, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 8, 0)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:values], [
            (DateTime("2000-01-01T00:00:00"), 0),
            (DateTime("2000-01-01T00:00:10"), 10),
            (DateTime("2000-01-01T00:01:00"), 100),
            (DateTime("2000-01-01T00:02:00"), 200),
            (DateTime("2000-01-01T00:02:59"), 259),
            (DateTime("2000-01-01T00:03:00"), 300),
            (DateTime("2000-01-01T00:04:00"), 400),
            (DateTime("2000-01-01T00:08:00"), 800)
        ])
    ])
    run!(exe, start, stop)

    buffer = output.operation.buffer
    display(buffer)

    @test buffer[1] == (DateTime("2000-01-01T00:00:00"), 0)
    @test buffer[2] == (DateTime("2000-01-01T00:01:00"), 100)
    @test buffer[3] == (DateTime("2000-01-01T00:02:00"), 200)
    @test buffer[4] == (DateTime("2000-01-01T00:03:00"), 300)
    @test buffer[5] == (DateTime("2000-01-01T00:04:00"), 400)
    @test buffer[6] == (DateTime("2000-01-01T00:08:00"), 800)
    @test length(buffer) == 6

    @test is_valid(g[:sampler].operation)
    reset!(g[:sampler].operation)
    @test !is_valid(g[:sampler].operation)
end

@testitem "sample every minute, custom origin (00:00:30)" begin
    using Dates
    
    g = StreamGraph()

    # sample every half minute, i.e. 00:30, 01:30, 02:30, etc.

    source!(g, :values, out=Int, init=0)

    op!(g, :sampler, TimeSampler{DateTime,Int}(Minute(1), origin=DateTime(0, 1, 1, 0, 0, 30)), out=Int)
    bind!(g, :values, :sampler)

    @test !is_valid(g[:sampler].operation)

    op!(g, :timestamper, Func{Tuple{DateTime,Int}}((exe, x) -> (time(exe), x), (DateTime(0), 0)), out=Tuple{DateTime,Int})
    bind!(g, :sampler, :timestamper)

    output = sink!(g, :output, Buffer{Tuple{DateTime,Int}}())
    bind!(g, :timestamper, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 8, 0)
    set_adapters!(exe, [
        HistoricIterable(exe, g[:values], [
            (DateTime("2000-01-01T00:00:00"), 0),   # 00:00:30 next sample (first)
            (DateTime("2000-01-01T00:00:10"), 10),  # 00:00:30 next sample (skip)
            (DateTime("2000-01-01T00:00:40"), 40),  # 00:01:30 next sample
            (DateTime("2000-01-01T00:01:00"), 100), # 00:01:30 next sample (skip)
            (DateTime("2000-01-01T00:02:00"), 200), # 00:02:30 next sample
            (DateTime("2000-01-01T00:02:10"), 210), # 00:02:30 next sample (skip)
            (DateTime("2000-01-01T00:02:59"), 259), # 00:03:30 next sample
            (DateTime("2000-01-01T00:03:00"), 300), # 00:03:30 next sample (skip)
            (DateTime("2000-01-01T00:03:30"), 330), # 00:04:30 next sample
            (DateTime("2000-01-01T00:04:00"), 400), # 00:04:30 next sample (skip)
            (DateTime("2000-01-01T00:08:00"), 800)  # 00:08:30 next sample
        ])
    ])
    run!(exe, start, stop)

    buffer = output.operation.buffer
    display(buffer)

    @test buffer[1] == (DateTime("2000-01-01T00:00:00"), 0)
    @test buffer[2] == (DateTime("2000-01-01T00:00:40"), 40)
    @test buffer[3] == (DateTime("2000-01-01T00:02:00"), 200)
    @test buffer[4] == (DateTime("2000-01-01T00:02:59"), 259)
    @test buffer[5] == (DateTime("2000-01-01T00:03:30"), 330)
    @test buffer[6] == (DateTime("2000-01-01T00:08:00"), 800)
    @test length(buffer) == 6
end
