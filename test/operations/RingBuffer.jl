using Test
using StreamOps
using Dates

@testset verbose = true "RingBuffer" begin

    @testset "RingBuffer{Int}(1) (discard 3)" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        sink!(g, :buffer, RingBuffer{Int}(1))

        @test g[:buffer].operation.min_count == 0

        bind!(g, :values, :buffer)

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

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
        @test get_state(g[:buffer].operation) == [4]
    end

    @testset "RingBuffer{Int}(4) (same as inputs)" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        sink!(g, :buffer, RingBuffer{Int}(4))

        @test g[:buffer].operation.min_count == 0

        bind!(g, :values, :buffer)

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

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

    @testset "RingBuffer{Int}(10) (larger than inputs)" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        sink!(g, :buffer, RingBuffer{Int}(10))

        @test g[:buffer].operation.min_count == 0

        bind!(g, :values, :buffer)

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

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

    @testset "RingBuffer{Int}(5, min_count=3)" begin
        g = StreamGraph()

        source!(g, :values, out=Int, init=0)
        op!(g, :buffer, RingBuffer{Int}(5, min_count=3), out=RingBuffer{Int})
        sink!(g, :output, Counter())

        @test g[:buffer].operation.min_count == 3

        bind!(g, :values, :buffer)
        bind!(g, :buffer, :output)

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

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

    @testset "RingBuffer{Float64}(5) w/ flush" begin
        g = StreamGraph()

        # Create source nodes
        source!(g, :timer, out=DateTime, init=DateTime(0))
        source!(g, :values, out=Float64, init=0.0)

        # Create operation nodes
        op!(g, :buffer, RingBuffer{Float64}(5), out=RingBuffer{Float64})
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

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

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
