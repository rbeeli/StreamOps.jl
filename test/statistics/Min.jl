@testitem "reset!" begin
    op = Min{Float64,Float64}(3)

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
    rolling_min = op!(g, :min, Min{Int,Float64}(3))
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, rolling_min)
    bind!(g, rolling_min, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    run!(exe, start, stop)
    # windows:
    # [1] min=1
    # [1,2] min=1
    # [1,2,3] min=1
    # [2,3,4] min=2
    # [3,4,1] min=1
    @test output.operation.buffer ≈ [1, 1, 1, 2, 1]
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
    rolling_min = op!(g, :min, Min{Int,Float64}(3; full_only=true))
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, rolling_min)
    bind!(g, rolling_min, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    run!(exe, start, stop)
    # full windows of size 3:
    # [1,2,3] min=1
    # [2,3,4] min=2
    # [3,4,1] min=1
    @test output.operation.buffer ≈ [1, 2, 1]
end

@testitem "NaN handling" begin
    op = Min{Float64,Float64}(2)

    op(nothing, NaN)
    @test is_valid(op)
    @test isnan(get_state(op))

    op(nothing, 1.0)
    @test isnan(get_state(op))

    op(nothing, 2.0) # drops the NaN
    @test get_state(op) == 1.0
end
