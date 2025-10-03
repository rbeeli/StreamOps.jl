@testitem "reset!" begin
    op = Quantile{Float64,Float64}(3, 0.75)

    @test !is_valid(op)

    op(nothing, 1.0)
    op(nothing, 2.0)

    @test is_valid(op)
    reset!(op)
    @test !is_valid(op)
end

@testitem "full_only=false" begin
    using Dates, Statistics

    q = 0.75
    window_size = 4

    g = StreamGraph()

    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
        (DateTime(2000, 1, 4), 4.0),
        (DateTime(2000, 1, 5), 1.0),
        (DateTime(2000, 1, 6), 5.0),
    ]
    values = source!(g, :values, HistoricIterable(Float64, values_data))
    quant = op!(g, :quant, Quantile{Float64,Float64}(window_size, q))
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, quant)
    bind!(g, quant, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 6)
    run!(exe, start, stop)

    raw_values = [v[2] for v in values_data]
    expected = Float64[]
    for i in eachindex(raw_values)
        window = raw_values[max(1, i - window_size + 1):i]
        push!(expected, quantile(window, q))
    end

    @test output.operation.buffer ≈ expected
end

@testitem "full_only=true" begin
    using Dates, Statistics

    q = 0.25
    window_size = 3

    g = StreamGraph()

    values_data = Tuple{DateTime,Float64}[
        (DateTime(2020, 1, 1), 4.0),
        (DateTime(2020, 1, 2), 1.0),
        (DateTime(2020, 1, 3), 3.0),
        (DateTime(2020, 1, 4), 2.0),
        (DateTime(2020, 1, 5), 5.0),
    ]
    values = source!(g, :values, HistoricIterable(Float64, values_data))
    quant = op!(g, :quant, Quantile{Float64,Float64}(window_size, q; full_only=true))
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, quant)
    bind!(g, quant, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2020, 1, 1)
    stop = DateTime(2020, 1, 5)
    run!(exe, start, stop)

    raw_values = [v[2] for v in values_data]
    expected = Float64[]
    for i in window_size:length(raw_values)
        window = raw_values[(i - window_size + 1):i]
        push!(expected, quantile(window, q))
    end

    @test output.operation.buffer ≈ expected
end

@testitem "extremes and NaNs" begin
    op_min = Quantile{Float64,Float64}(4, 0.0)
    for v in (4.0, 1.0, 3.0, 2.0)
        op_min(nothing, v)
    end
    @test get_state(op_min) ≈ 1.0

    op_max = Quantile{Float64,Float64}(4, 1.0)
    for v in (4.0, 1.0, 3.0, 2.0)
        op_max(nothing, v)
    end
    @test get_state(op_max) ≈ 4.0

    op_nan = Quantile{Float64,Float64}(3, 0.75)
    op_nan(nothing, 1.0)
    @test get_state(op_nan) ≈ 1.0
    op_nan(nothing, NaN)
    @test isnan(get_state(op_nan))
    op_nan(nothing, 2.0)
    @test isnan(get_state(op_nan))
    op_nan(nothing, 3.0)
    @test isnan(get_state(op_nan))
    op_nan(nothing, 4.0)
    @test get_state(op_nan) ≈ 3.5
end
