using Test
using StreamOps
using Dates

@testset verbose = true "TimeBuffer" begin

    @testset "copy=true :closed (included)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        rolling = op!(g, :rolling, TimeBuffer{DateTime,Int}(Minute(2), :closed, copy=true), out=Vector{Int})

        @test rolling.operation.copy
        @test is_valid(values.operation) # != nothing -> is_valid
        @test !is_valid(rolling.operation)

        output = sink!(g, :output, Buffer{Vector{Int}}())

        bind!(g, values, rolling)
        bind!(g, rolling, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1, 0, 0, 0)
        stop = DateTime(2000, 1, 1, 0, 10, 0)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1, 0, 0, 0), 1),
                (DateTime(2000, 1, 1, 0, 1, 0), 2),
                (DateTime(2000, 1, 1, 0, 2, 0), 3),
                (DateTime(2000, 1, 1, 0, 3, 0), 4),
                (DateTime(2000, 1, 1, 0, 10, 0), 10)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)

        # values right on the cutoff time are included
        @test output.operation.buffer[1] == [1]
        @test output.operation.buffer[2] == [1, 2]
        @test output.operation.buffer[3] == [1, 2, 3]
        @test output.operation.buffer[4] == [2, 3, 4]
        @test output.operation.buffer[5] == [10]
        @test length(output.operation.buffer) == 5
    end

    @testset "copy=true :open (excluded)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        rolling = op!(g, :rolling, TimeBuffer{DateTime,Int}(Minute(2), :open, copy=true), out=Vector{Int})

        @test rolling.operation.copy
        @test is_valid(values.operation) # != nothing -> is_valid
        @test !is_valid(rolling.operation)

        output = sink!(g, :output, Buffer{Vector{Int}}())

        bind!(g, values, rolling)
        bind!(g, rolling, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1, 0, 0, 0)
        stop = DateTime(2000, 1, 1, 0, 10, 0)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1, 0, 0, 0), 1),
                (DateTime(2000, 1, 1, 0, 1, 0), 2),
                (DateTime(2000, 1, 1, 0, 2, 0), 3),
                (DateTime(2000, 1, 1, 0, 3, 0), 4),
                (DateTime(2000, 1, 1, 0, 10, 0), 10)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)

        # values right on the cutoff time are excluded
        @test output.operation.buffer[1] isa Vector{Int}
        @test output.operation.buffer[1] == [1]
        @test output.operation.buffer[2] == [1, 2]
        @test output.operation.buffer[3] == [2, 3]
        @test output.operation.buffer[4] == [3, 4]
        @test output.operation.buffer[5] == [10]
        @test length(output.operation.buffer) == 5
    end

    @testset "copy=false" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        rolling = op!(g, :rolling, TimeBuffer{DateTime,Int}(Minute(2), :closed; copy=false), out=AbstractVector{Int})

        @test !rolling.operation.copy
        @test is_valid(values.operation) # != nothing -> is_valid
        @test !is_valid(rolling.operation)

        output = sink!(g, :output, Buffer{AbstractVector{Int}}())

        bind!(g, values, rolling)
        bind!(g, rolling, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1, 0, 0, 0)
        stop = DateTime(2000, 1, 1, 0, 1, 0)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1, 0, 0, 0), 1),
            ])
        ]
        run_simulation!(exe, adapters, start, stop)

        @test output.operation.buffer[1] == [1]
        @test typeof(output.operation.buffer[1]) !== Vector{Int}
        @test length(output.operation.buffer) == 1
    end

end
