@testitem "Diff (incl. reset!)" begin
    using Dates
    
    g = StreamGraph()

    values_data = Tuple{DateTime,Int}[
        (DateTime(2000, 1, 1), 1),
        (DateTime(2000, 1, 2), -2),
        (DateTime(2000, 1, 3), 6),
        (DateTime(2000, 1, 4), 0),
        (DateTime(2000, 1, 5), 10),
    ]
    values = source!(g, :values, HistoricIterable(Int, values_data))
    diff = op!(g, :diff, Diff{Int}())
    output = sink!(g, :output, Buffer{Int}())

    bind!(g, values, diff)
    bind!(g, diff, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    run!(exe, start, stop)
    @test output.operation.buffer ≈ [-3, 8, -6, 10]

    reset!(g[:diff].operation)
    @test get_state(g[:diff].operation) == 0
end
