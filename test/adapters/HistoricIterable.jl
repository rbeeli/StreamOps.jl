using Test
using StreamOps
using DataStructures

@testset verbose = true "HistoricIterable" begin

    @testset "default" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        buffer = sink!(g, :buffer, Buffer{Int}())

        @test buffer.operation.min_count == 0

        bind!(g, values, buffer)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        adapter = HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3)
        ])

        # first event is scheduled
        setup!(adapter, exe)

        @test length(exe.event_queue) == 1
        evt = pop!(exe.event_queue)
        @test evt.timestamp == DateTime(2000, 1, 1)
        @test evt.source_index == 1

        # second event is executed
        advance!(adapter, exe)

        @test length(exe.event_queue) == 1
        evt = pop!(exe.event_queue)
        @test evt.timestamp == DateTime(2000, 1, 2)
        @test evt.source_index == 1

        # third event is executed
        advance!(adapter, exe)

        @test length(exe.event_queue) == 1
        evt = pop!(exe.event_queue)
        @test evt.timestamp == DateTime(2000, 1, 3)
        @test evt.source_index == 1

        # no more events
        advance!(adapter, exe)

        @test length(exe.event_queue) == 0
    end

end
