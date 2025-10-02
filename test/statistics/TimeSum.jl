@testitem "default (incl. reset!)" begin
    using Dates

    g = StreamGraph()

    values_data = Tuple{DateTime,Int}[
        (DateTime(2000, 1, 1, 0, 0, 0), 1),
        (DateTime(2000, 1, 1, 0, 1, 0), 2),
        (DateTime(2000, 1, 1, 0, 2, 0), 3),
        (DateTime(2000, 1, 1, 0, 3, 0), 4),
        (DateTime(2000, 1, 1, 0, 10, 0), 10),
    ]
    values = source!(g, :values, HistoricIterable(Int, values_data))
    rolling = op!(g, :rolling, TimeSum{DateTime,Int}(Minute(2), :closed))

    @test !is_valid(values.operation)
    @test !is_valid(rolling.operation)

    output = sink!(g, :output, Buffer{Int}())

    bind!(g, values, rolling)
    bind!(g, rolling, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 10, 0)
    run!(exe, start, stop)

    # values right on the cutoff time are included
    @test output.operation.buffer[1] == sum([1])
    @test output.operation.buffer[2] == sum([1, 2])
    @test output.operation.buffer[3] == sum([1, 2, 3])
    @test output.operation.buffer[4] == sum([2, 3, 4])
    @test output.operation.buffer[5] == sum([10])
    @test length(output.operation.buffer) == 5

    @test is_valid(rolling.operation)
    reset!(rolling.operation)
    @test !is_valid(rolling.operation)
end
