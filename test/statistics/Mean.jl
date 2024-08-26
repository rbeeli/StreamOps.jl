using Test
using StreamOps

@testset verbose = true "Mean" begin

    @testset "full_only=false(default)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        avg = op!(g, :avg, Mean{Int,Float64}(3), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, avg)
        bind!(g, avg, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 1)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)
        @test output.operation.buffer ≈ [1, (1 + 2) / 2, (1 + 2 + 3) / 3, (2 + 3 + 4) / 3, (3 + 4 + 1) / 3]
    end

    @testset "full_only=true" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        avg = op!(g, :avg, Mean{Int,Float64}(3; full_only=true), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, avg)
        bind!(g, avg, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        adapters = [
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 1)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)
        @test output.operation.buffer ≈ [(1 + 2 + 3) / 3, (2 + 3 + 4) / 3, (3 + 4 + 1) / 3]
    end

end
