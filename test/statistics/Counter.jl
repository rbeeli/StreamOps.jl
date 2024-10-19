using Test
using StreamOps

@testset "Counter" begin
    g = StreamGraph()

    timer = source!(g, :timer, out=DateTime, init=DateTime(0))
    counter = sink!(g, :counter, Counter())
    bind!(g, timer, counter)

    exe = compile_historic_executor(DateTime, g; debug=!true)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 0, 15)
    adapters = [
        HistoricTimer{DateTime}(exe, timer; interval=Dates.Second(5), start_time=start),
    ]
    run_simulation!(exe, adapters, start, stop)
    @test get_state(counter.operation) == 4 # 0, 5, 10, 15

    reset!(counter.operation)
    @test get_state(counter.operation) == 0
end
