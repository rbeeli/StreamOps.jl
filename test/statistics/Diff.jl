using Test
using StreamOps

@testset "Diff" begin
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    diff_buffer = op!(g, :diff_buffer, WindowBuffer{Int}(2, init_value=0), out=AbstractVector{Int})
    diff = op!(g, :diff, Diff{Int}(), out=Int)
    output = sink!(g, :output, Buffer{Int}())

    bind!(g, values, diff_buffer)
    bind!(g, diff_buffer, diff)
    bind!(g, diff, output)

    exe = compile_historic_executor(DateTime, g; debug=!true)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    adapters = [
        IterableAdapter(exe, values, [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), -2),
            (DateTime(2000, 1, 3), 6),
            (DateTime(2000, 1, 4), 0),
            (DateTime(2000, 1, 5), 10)
        ])
    ]
    run_simulation!(exe, adapters; start_time=start, end_time=stop)
    @test output.operation.buffer ≈ [-3, 8, -6, 10]
end
