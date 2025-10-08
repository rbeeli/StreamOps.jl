@testitem "reset!" begin
    op = Min{Float64}(3)

    @test !is_valid(op)

    op(nothing, 1.0)
    op(nothing, 2.0)
    op(nothing, 3.0)

    @test is_valid(op)
    reset!(op)
    @test !is_valid(op)
end

@testitem "rolling window behaviour" begin
    using Dates
    
    g = StreamGraph()

    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
        (DateTime(2000, 1, 4), 4.0),
        (DateTime(2000, 1, 5), 1.0),
    ]
    values = source!(g, :values, HistoricIterable(Float64, values_data))
    rolling_min = op!(g, :min, Min{Float64}(3))
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
    @test output.operation.buffer ≈ [1.0, 1.0, 1.0, 2.0, 1.0]
end

@testitem "NaN handling" begin
    op = Min{Float64}(2)

    op(nothing, NaN)
    @test is_valid(op)
    @test isnan(get_state(op))

    op(nothing, 1.0)
    @test isnan(get_state(op))

    op(nothing, 2.0) # drops the NaN
    @test get_state(op) == 1.0
end
