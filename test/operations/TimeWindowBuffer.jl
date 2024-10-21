@testitem "copy=true :closed (included)" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, TimeWindowBuffer{DateTime,Int}(Minute(2), :closed, copy=true), out=Vector{Int})

    @test rolling.operation.copy
    @test is_valid(values.operation) # != nothing -> is_valid
    @test is_valid(rolling.operation) # valid_if_empty=true is default

    output = sink!(g, :output, Buffer{Vector{Int}}())

    bind!(g, values, rolling)
    bind!(g, rolling, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 10, 0)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1, 0, 0, 0), 1),
            (DateTime(2000, 1, 1, 0, 1, 0), 2),
            (DateTime(2000, 1, 1, 0, 2, 0), 3),
            (DateTime(2000, 1, 1, 0, 3, 0), 4),
            (DateTime(2000, 1, 1, 0, 10, 0), 10)
        ])
    ])
    run!(exe, start, stop)

    # values right on the cutoff time are included
    @test output.operation.buffer[1] == [1]
    @test output.operation.buffer[2] == [1, 2]
    @test output.operation.buffer[3] == [1, 2, 3]
    @test output.operation.buffer[4] == [2, 3, 4]
    @test output.operation.buffer[5] == [10]
    @test length(output.operation.buffer) == 5
end

@testitem "copy=true :open (excluded) valid_if_empty=false" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, TimeWindowBuffer{DateTime,Int}(Minute(2), :open, copy=true, valid_if_empty=false), out=Vector{Int})

    @test rolling.operation.copy
    @test is_valid(values.operation) # != nothing -> is_valid
    @test !is_valid(rolling.operation) # valid_if_empty=false

    output = sink!(g, :output, Buffer{Vector{Int}}())

    bind!(g, values, rolling)
    bind!(g, rolling, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 10, 0)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1, 0, 0, 0), 1),
            (DateTime(2000, 1, 1, 0, 1, 0), 2),
            (DateTime(2000, 1, 1, 0, 2, 0), 3),
            (DateTime(2000, 1, 1, 0, 3, 0), 4),
            (DateTime(2000, 1, 1, 0, 10, 0), 10)
        ])
    ])
    run!(exe, start, stop)

    # values right on the cutoff time are excluded
    @test output.operation.buffer[1] isa Vector{Int}
    @test output.operation.buffer[1] == [1]
    @test output.operation.buffer[2] == [1, 2]
    @test output.operation.buffer[3] == [2, 3]
    @test output.operation.buffer[4] == [3, 4]
    @test output.operation.buffer[5] == [10]
    @test length(output.operation.buffer) == 5
end

@testitem "copy=false" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, TimeWindowBuffer{DateTime,Int}(Minute(2), :closed; copy=false), out=AbstractVector{Int})

    @test !rolling.operation.copy

    output = sink!(g, :output, Buffer{AbstractVector{Int}}())

    bind!(g, values, rolling)
    bind!(g, rolling, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 1, 0)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1, 0, 0, 0), 1),
        ])
    ])
    run!(exe, start, stop)

    @test output.operation.buffer[1] == [1]
    @test typeof(output.operation.buffer[1]) !== Vector{Int}
    @test length(output.operation.buffer) == 1
end

@testitem "multi-sources time update" begin
    using Dates
    
    """
    Ensure that time buffer is kept up-to-date when multiple sources are used,
    i.e. ensure time is updated when the source with the latest time is updated,
    even if time buffer itself is not called directly.
    """

    g = StreamGraph()

    source!(g, :timer, out=DateTime, init=DateTime(0))
    source!(g, :values, out=Int, init=0)

    op!(g, :rolling, TimeWindowBuffer{DateTime,Int}(Day(2), :closed; copy=true), out=Vector{Int})
    bind!(g, :values, :rolling)

    sink!(g, :output, Buffer{Tuple{DateTime,Vector{Int}}}())
    bind!(g, (:timer, :rolling), :output,
        bind_as=TupleParams(), call_policies=IfExecuted(:timer))

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 7)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer]; interval=Day(1), start_time=start + Second(1)),
        HistoricIterable(exe, g[:values], [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 6), 6),
        ])
    ])
    run!(exe, start, stop)

    buffer = g[:output].operation.buffer
    # display(buffer)

    @test length(buffer) == 6
    @test buffer[1][2] == [1]
    @test buffer[2][2] == [1, 2]
    @test buffer[3][2] == [2]
    @test buffer[4][2] == Int[] # :rolling not directly called, but executor calls update_time!
    @test buffer[5][2] == Int[] # :rolling not directly called, but executor calls update_time!
    @test buffer[6][2] == [6]
end
