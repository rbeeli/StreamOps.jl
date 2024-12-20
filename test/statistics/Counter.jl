@testitem "Counter (incl. reset!)" begin
    using Dates
    
    g = StreamGraph()

    source!(g, :timer, out=DateTime, init=DateTime(0))
    sink!(g, :counter, Counter())
    bind!(g, :timer, :counter)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 0, 15)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer], interval=Second(5), start_time=start),
    ])
    run!(exe, start, stop)

    @test get_state(g[:counter].operation) == 4 # 0, 5, 10, 15

    reset!(g[:counter].operation)
    @test get_state(g[:counter].operation) == 0
end

@testitem "Counter min_count" begin
    using Dates
    
    g = StreamGraph()

    source!(g, :timer, out=DateTime, init=DateTime(0))
    op!(g, :counter, Counter(min_count=3), out=Int)
    bind!(g, :timer, :counter)
    sink!(g, :output, Buffer{Int}())
    bind!(g, :counter, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 15)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer], interval=Day(1), start_time=start),
    ])
    run!(exe, start, stop)

    @test get_state(g[:counter].operation) == 15

    # from 3 onwards it should be valid and start collecting
    @test all(get_state(g[:output].operation) .== 3:15)
end
