@testitem "Buffer{Int}()" begin
    using Dates

    g = StreamGraph()

    values_data = Tuple{DateTime,Int}[
        (DateTime(2000, 1, 1), 1),
        (DateTime(2000, 1, 2), 2),
        (DateTime(2000, 1, 3), 3),
        (DateTime(2000, 1, 4), 4),
    ]
    source!(g, :values, HistoricIterable(Int, values_data))
    sink!(g, :buffer, Buffer{Int}())

    op = g[:buffer].operation

    @test op.min_count == 0

    bind!(g, :values, :buffer)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    run!(exe, start, stop)
    @test get_state(op) == [1, 2, 3, 4]

    @test is_valid(op)
    reset!(op)
    @test is_valid(op) # min_count=0
end

@testitem "Buffer{Float32}() w/ Float64 input and NO automatic casting (error)" begin
    using Dates

    g = StreamGraph()

    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
        (DateTime(2000, 1, 4), 4.0),
    ]
    source!(g, :values, HistoricIterable(Float64, values_data))
    sink!(g, :buffer, Buffer{Float32}(; auto_cast=false))

    op = g[:buffer].operation

    @test op.min_count == 0

    bind!(g, :values, :buffer)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    @test_throws "MethodError: no method matching" run!(exe, start, stop)

    @test is_valid(op)
    reset!(op)
    @test is_valid(op) # min_count=0
end

@testitem "Buffer{Float32}() w/ Float64 input and automatic casting" begin
    using Dates

    g = StreamGraph()

    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
        (DateTime(2000, 1, 4), 4.0),
    ]
    source!(g, :values, HistoricIterable(Float64, values_data))
    sink!(g, :buffer, Buffer{Float32}(; auto_cast=true))

    @test g[:buffer].operation.min_count == 0

    bind!(g, :values, :buffer)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    run!(exe, start, stop)
    @test get_state(g[:buffer].operation) == [1.0f0, 2.0f0, 3.0f0, 4.0f0]
end

@testitem "Buffer{Int}(storage)" begin
    using Dates

    g = StreamGraph()

    storage = Int[]
    values_data = Tuple{DateTime,Int}[
        (DateTime(2000, 1, 1), 1),
        (DateTime(2000, 1, 2), 2),
        (DateTime(2000, 1, 3), 3),
        (DateTime(2000, 1, 4), 4),
    ]
    source!(g, :values, HistoricIterable(Int, values_data))
    sink!(g, :buffer, Buffer{Int}(storage))

    @test g[:buffer].operation.min_count == 0

    bind!(g, :values, :buffer)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    run!(exe, start, stop)
    @test storage == [1, 2, 3, 4]
end

@testitem "Buffer{Int}(min_count=3)" begin
    using Dates

    g = StreamGraph()

    values_data = Tuple{DateTime,Int}[
        (DateTime(2000, 1, 1), 1),
        (DateTime(2000, 1, 2), 2),
        (DateTime(2000, 1, 3), 3),
        (DateTime(2000, 1, 4), 4),
    ]
    source!(g, :values, HistoricIterable(Int, values_data))
    op!(g, :buffer, Buffer{Int}(; min_count=3); out=Vector{Int})
    sink!(g, :output, Counter())

    op = g[:buffer].operation

    @test op.min_count == 3

    bind!(g, :values, :buffer)
    bind!(g, :buffer, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    run!(exe, start, stop)

    # output should only be called twice because of min_count=3
    @test get_state(g[:output].operation) == 2

    @test is_valid(op)
    reset!(op)
    @test !is_valid(op)
end

@testitem "Buffer{Float64}() w/ flush" begin
    using Dates

    g = StreamGraph()

    # Create source nodes
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 6)
    source!(g, :timer, HistoricTimer(interval=Day(2), start_time=start))
    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
        (DateTime(2000, 1, 4), 4.0),
        (DateTime(2000, 1, 5), 5.0),
        (DateTime(2000, 1, 6), 6.0),
    ]
    source!(g, :values, HistoricIterable(Float64, values_data))

    # Create operation nodes
    op!(g, :buffer, Buffer{Float64}(); out=Buffer{Float64})
    op!(
        g,
        :flush_buffer,
        Func{Vector{Float64}}((exe, buf, dt) -> begin
            vals = copy(buf)
            empty!(buf)
            vals
        end, Float64[]);
        out=Vector{Float64},
    )

    @test g[:buffer].operation.min_count == 0

    # Create sink nodes
    collected = []
    sink!(g, :output, Func((exe, x) -> push!(collected, collect(x)), nothing))

    # Create edges between nodes (define the computation graph)
    bind!(g, :values, :buffer)
    bind!(g, :buffer, :flush_buffer; call_policies=[Never()])
    bind!(g, :timer, :flush_buffer)
    bind!(g, :flush_buffer, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    run!(exe, start, stop)
    @test collected[1] == Float64[]
    @test collected[2] == [1.0, 2.0]
    @test collected[3] == [3.0, 4.0]
    @test length(collected) == 3
end
