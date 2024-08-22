using Test
using StreamOps

@testset "WindowBuffer <Always>" begin
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, WindowBuffer{Int}(3, init_value=-1), out=AbstractVector{Int})
    
    @test is_valid(values.operation) # != nothing -> is_valid
    @test !is_valid(rolling.operation)

    collected = []
    output = sink!(g, :output, Func((exe, x) -> push!(collected, collect(x))))

    bind!(g, values, rolling)
    bind!(g, rolling, output, call_policies=[Always()])

    exe = compile_historic_executor(DateTime, g; debug=!true)
    
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    adapters = [
        IterableAdapter(exe, values, [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ])
    ]
    run_simulation!(exe, adapters; start_time=start, end_time=stop)
    @test all(get_state(rolling.operation) .== [2, 3, 4])
    @test collected[1] == [-1, -1, 1]
    @test collected[2] == [-1, 1, 2]
    @test collected[3] == [1, 2, 3]
    @test collected[4] == [2, 3, 4]
    @test length(collected) == 4
end

@testset "WindowBuffer <default>" begin
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, WindowBuffer{Int}(3, init_value=-1), out=AbstractVector{Int})
    
    @test is_valid(values.operation) # != nothing -> is_valid
    @test !is_valid(rolling.operation)

    collected = []
    output = sink!(g, :output, Func((exe, x) -> push!(collected, collect(x))))

    bind!(g, values, rolling)
    bind!(g, rolling, output)

    exe = compile_historic_executor(DateTime, g; debug=!true)
    
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    adapters = [
        IterableAdapter(exe, values, [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ])
    ]
    run_simulation!(exe, adapters; start_time=start, end_time=stop)
    @test all(get_state(rolling.operation) .== [2, 3, 4])
    @test collected[1] == [1, 2, 3]
    @test collected[2] == [2, 3, 4]
    @test length(collected) == 2
end
