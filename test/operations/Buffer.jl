using Test
using StreamOps

@testset verbose = true "Buffer" begin

    @testset "default" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = sink!(g, :buffer, Buffer{Int}())

        bind!(g, values, buffer)

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
        @test get_state(buffer.operation) == [1, 2, 3, 4]
    end

    @testset "w/ flush" begin
        g = StreamGraph()

        # Create source nodes
        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        # Create operation nodes
        buffer = op!(g, :buffer, Buffer{Float64}(), out=Buffer{Float64})
        flush_buffer = op!(g, :flush_buffer, Func{Vector{Float64}}((exe, buf, dt) -> begin
                    vals = copy(buf)
                    empty!(buf)
                    vals
                end, Float64[]), out=Vector{Float64})

        # Create sink nodes
        collected = []
        output = sink!(g, :output, Func((exe, x) -> push!(collected, collect(x))))

        # Create edges between nodes (define the computation graph)
        bind!(g, values, buffer)
        bind!(g, buffer, flush_buffer; call_policies=[Never()])
        bind!(g, timer, flush_buffer)
        bind!(g, flush_buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 6)
        adapters = [
            TimerAdapter{DateTime}(exe, timer; interval=Dates.Day(2), start_time=start),
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 3.0),
                (DateTime(2000, 1, 4), 4.0),
                (DateTime(2000, 1, 5), 5.0),
                (DateTime(2000, 1, 6), 6.0)
            ])
        ]
        run_simulation!(exe, adapters; start_time=start, end_time=stop)
        @test collected[1] == Float64[]
        @test collected[2] == [1.0, 2.0]
        @test collected[3] == [3.0, 4.0]
        @test length(collected) == 3
    end

end
