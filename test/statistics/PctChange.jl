using Test
using StreamOps

@testset verbose = true "PctChange" begin

    @testset "default" begin
        g = StreamGraph()

        values = source!(g, :values, out=Int, init=0)
        pct_change = op!(g, :pct_change, PctChange{Int,Float64}(), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, pct_change)
        bind!(g, pct_change, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        adapters = [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), 2),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4),
                (DateTime(2000, 1, 5), 1)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)
        @test output.operation.buffer ≈ [1.0, 0.5, 0.3333333333333333, -0.75]
    end

end
