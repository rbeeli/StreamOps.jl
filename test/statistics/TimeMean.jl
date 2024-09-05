using Test
using StreamOps
using Dates

@testset verbose = true "TimeMean" begin

    @testset "default" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        rolling = op!(g, :rolling, TimeMean{DateTime,Int,Float64}(Minute(2), :closed), out=Float64)

        @test is_valid(values.operation) # != nothing -> is_valid
        @test !is_valid(rolling.operation)

        output = sink!(g, :output, Buffer{Float64}())

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
        @test output.operation.buffer[1] == sum([1]) / 1.0
        @test output.operation.buffer[2] == sum([1, 2]) / 2.0
        @test output.operation.buffer[3] == sum([1, 2, 3]) / 3.0
        @test output.operation.buffer[4] == sum([2, 3, 4]) / 3.0
        @test output.operation.buffer[5] == sum([10]) / 1.0
        @test length(output.operation.buffer) == 5
    end

end
