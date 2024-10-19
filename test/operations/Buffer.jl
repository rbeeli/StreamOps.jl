using Test
using StreamOps
using Dates

@testset verbose = true "Buffer" begin

    @testset "Buffer{Int}()" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        sink!(g, :buffer, Buffer{Int}())

        @test g[:buffer].operation.min_count == 0

        bind!(g, :values, :buffer)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        set_adapters!(exe, [
            HistoricIterable(exe, g[:values], [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4)
            ])
        ])
        run!(exe, start, stop)
        @test get_state(g[:buffer].operation) == [1, 2, 3, 4]
    end

    @testset "Buffer{Int}(storage)" begin
        g = StreamGraph()

        storage = Int[]
        source!(g, :values, out=Int, init=0)
        sink!(g, :buffer, Buffer{Int}(storage))

        @test g[:buffer].operation.min_count == 0

        bind!(g, :values, :buffer)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        set_adapters!(exe, [
            HistoricIterable(exe, g[:values], [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4)
            ])
        ])
        run!(exe, start, stop)
        @test storage == [1, 2, 3, 4]
    end

    @testset "Buffer{Int}(min_count=3)" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        op!(g, :buffer, Buffer{Int}(min_count=3), out=Vector{Int})
        sink!(g, :output, Counter())

        @test g[:buffer].operation.min_count == 3

        bind!(g, :values, :buffer)
        bind!(g, :buffer, :output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        set_adapters!(exe, [
            HistoricIterable(exe, g[:values], [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4)
            ])
        ])
        run!(exe, start, stop)
        
        # output should only be called twice because of min_count=3
        @test get_state(g[:output].operation) == 2
    end

    @testset "Buffer{Float64}() w/ flush" begin
        g = StreamGraph()

        # Create source nodes
        source!(g, :timer, out=DateTime, init=DateTime(0))
        source!(g, :values, out=Float64, init=0.0)

        # Create operation nodes
        op!(g, :buffer, Buffer{Float64}(), out=Buffer{Float64})
        op!(g, :flush_buffer, Func{Vector{Float64}}((exe, buf, dt) -> begin
                vals = copy(buf)
                empty!(buf)
                vals
            end, Float64[]), out=Vector{Float64})

        @test g[:buffer].operation.min_count == 0

        # Create sink nodes
        collected = []
        sink!(g, :output, Func((exe, x) -> push!(collected, collect(x)), nothing))

        # Create edges between nodes (define the computation graph)
        bind!(g, :values, :buffer)
        bind!(g, :buffer, :flush_buffer; call_policies=[Never()])
        bind!(g, :timer, :flush_buffer)
        bind!(g, :flush_buffer, :output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 6)
        set_adapters!(exe, [
            HistoricTimer{DateTime}(exe, g[:timer]; interval=Day(2), start_time=start),
            HistoricIterable(exe, g[:values], [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 3.0),
                (DateTime(2000, 1, 4), 4.0),
                (DateTime(2000, 1, 5), 5.0),
                (DateTime(2000, 1, 6), 6.0)
            ])
        ])
        run!(exe, start, stop)
        @test collected[1] == Float64[]
        @test collected[2] == [1.0, 2.0]
        @test collected[3] == [3.0, 4.0]
        @test length(collected) == 3
    end

end
