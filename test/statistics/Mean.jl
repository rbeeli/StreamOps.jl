@testitem "reset!" begin
    op = Mean{Float64,Float64}(3)

    @test !is_valid(op)

    op(nothing, 1.0)
    op(nothing, 2.0)
    op(nothing, 3.0)

    @test is_valid(op)
    reset!(op)
    @test !is_valid(op)
end

@testitem "full_only=false(default)" begin
    using Dates
    
    g = StreamGraph()

    values_data = Tuple{DateTime,Int}[
        (DateTime(2000, 1, 1), 1),
        (DateTime(2000, 1, 2), 2),
        (DateTime(2000, 1, 3), 3),
        (DateTime(2000, 1, 4), 4),
        (DateTime(2000, 1, 5), 1),
    ]
    values = source!(g, :values, HistoricIterable(Int, values_data))
    avg = op!(g, :avg, Mean{Int,Float64}(3), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    run!(exe, start, stop)
    @test output.operation.buffer ≈ [1, (1 + 2) / 2, (1 + 2 + 3) / 3, (2 + 3 + 4) / 3, (3 + 4 + 1) / 3]
end

@testitem "full_only=true" begin
    using Dates
    
    g = StreamGraph()

    values_data = Tuple{DateTime,Int}[
        (DateTime(2000, 1, 1), 1),
        (DateTime(2000, 1, 2), 2),
        (DateTime(2000, 1, 3), 3),
        (DateTime(2000, 1, 4), 4),
        (DateTime(2000, 1, 5), 1),
    ]
    values = source!(g, :values, HistoricIterable(Int, values_data))
    avg = op!(g, :avg, Mean{Int,Float64}(3; full_only=true), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    run!(exe, start, stop)
    @test output.operation.buffer ≈ [(1 + 2 + 3) / 3, (2 + 3 + 4) / 3, (3 + 4 + 1) / 3]
end
