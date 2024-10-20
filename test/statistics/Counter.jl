using Test
using StreamOps
using Dates

@testset "Counter" begin
    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    counter = sink!(g, :counter, Counter())
    bind!(g, timer, counter)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 0, 15)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, timer; interval=Second(5), start_time=start),
    ])
    run!(exe, start, stop)
    @test get_state(counter.operation) == 4 # 0, 5, 10, 15

    reset!(counter.operation)
    @test get_state(counter.operation) == 0
end
