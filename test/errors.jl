@testitem "debug=true" begin
    using Dates
    
    g = StreamGraph()

    source!(g, :values, out=Int, init=0)
    op!(g, :buffer, Func((exe, x) -> throw(ErrorException("My error")), 0), out=Int)
    sink!(g, :output, Buffer{Int}())

    bind!(g, :values, :buffer)
    bind!(g, :buffer, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe, debug=true)

    vals = [2, 3, -1, 0, 3]
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, g[:values], [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    
    err_msg = "StreamOpsError at node [buffer]: Execution of node [buffer] with inputs [values] at time 2000-01-01T00:00:00 failed. Inner exception: My error"
    @test_throws err_msg run!(exe, start, stop)
end
