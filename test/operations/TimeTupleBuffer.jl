using Test
using StreamOps
using Dates

@testset verbose = true "TimeTupleBuffer" begin

    @testset "default" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = sink!(g, :buffer, TimeTupleBuffer{DateTime,Int}())

        @test buffer.operation.min_count == 0

        bind!(g, values, buffer)

        exe = compile_historic_executor(DateTime, g; debug=!true)
        input = [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        set_adapters!(exe, [
            HistoricIterable(exe, values, input)
        ])
        run!(exe, start, stop)

        actual = get_state(buffer.operation)
        @test length(actual) == 4
        @test all(actual .== input)
    end

    @testset "min_count" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = op!(g, :buffer, TimeTupleBuffer{DateTime,Int}(min_count=3), out=Vector{Tuple{DateTime,Int}})
        output = sink!(g, :output, Counter())

        @test buffer.operation.min_count == 3

        bind!(g, values, buffer)
        bind!(g, buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)
        input = [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        set_adapters!(exe, [
            HistoricIterable(exe, values, input)
        ])
        run!(exe, start, stop)
        
        # output should only be called twice because of min_count=3
        @test get_state(output.operation) == 2
    end

    @testset "w/ flush" begin
        g = StreamGraph()

        # Create source nodes
        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        # Create operation nodes
        buffer = op!(g, :buffer, TimeTupleBuffer{DateTime,Float64}(), out=TimeTupleBuffer{DateTime,Float64})
        flush_buffer = op!(g, :flush_buffer, Func{Vector{Tuple{DateTime,Float64}}}((exe, buf, dt) -> begin
                    vals = copy(buf)
                    empty!(buf)
                    vals
                end, Tuple{DateTime,Float64}[]), out=Vector{Tuple{DateTime,Float64}})

        @test buffer.operation.min_count == 0

        # Create sink nodes
        collected = []
        output = sink!(g, :output, Func((exe, x) -> push!(collected, collect(x)), nothing))

        # Create edges between nodes (define the computation graph)
        bind!(g, values, buffer)
        bind!(g, buffer, flush_buffer; call_policies=[Never()])
        bind!(g, timer, flush_buffer)
        bind!(g, flush_buffer, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)
        input = [
            (DateTime(2000, 1, 1), 1.0),
            (DateTime(2000, 1, 2), 2.0),
            (DateTime(2000, 1, 3), 3.0),
            (DateTime(2000, 1, 4), 4.0),
            (DateTime(2000, 1, 5), 5.0),
            (DateTime(2000, 1, 6), 6.0)
        ]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 6)
        set_adapters!(exe, [
            HistoricTimer{DateTime}(exe, timer; interval=Day(2), start_time=start),
            HistoricIterable(exe, values, input)
        ])
        run!(exe, start, stop)
        @test collected[1] == Tuple{DateTime,Float64}[]
        @test collected[2] == input[1:2]
        @test collected[3] == input[3:4]
        @test length(collected) == 3
    end

end
