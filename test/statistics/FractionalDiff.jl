@testitem "reset!" begin
    op = FractionalDiff{Float64,Float64}(0.99999)

    op(nothing, 1.0)
    op(nothing, 2.0)
    op(nothing, 3.0)

    @test is_valid(op)
    reset!(op)
    @test !is_valid(op)
end

@testitem "order=0.99" begin
    using Dates
    
    g = StreamGraph()

    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, #
        -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, #
        50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]
    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, i), x)
        for (i, x) in enumerate(vals)
    ]

    values = source!(g, :values, HistoricIterable(Float64, values_data))
    frac_diff = op!(g, :frac_diff, FractionalDiff{Float64,Float64}(0.99), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, frac_diff)
    bind!(g, frac_diff, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    run!(exe, start, stop)

    # Reference values generated using Python script ./FractionalDiff.py
    expected = [3.0735819920702734, -6.859030168988753, 153.02035742475738,
        -548.4410855286475, 445.29766956916126, -46.23978225929855,
        -0.053730985383909635, 3.0735819920702734, -6.859030168988753,
        153.02035742475738, -548.4410855286475, 445.29766956916126,
        -46.23978225929855, -0.053730985383909635, 3.0735819920702734,
        -6.859030168988753, 153.02035742475738, -548.4410855286475]
    @test output.operation.buffer ≈ expected atol = 1e-5
end

@testitem "order=1 (First Difference)" begin
    using Dates
    
    g = StreamGraph()

    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 3.0),
        (DateTime(2000, 1, 3), 6.0),
        (DateTime(2000, 1, 4), 10.0),
        (DateTime(2000, 1, 5), 15.0),
    ]

    values = source!(g, :values, HistoricIterable(Float64, values_data))
    frac_diff = op!(g, :frac_diff, FractionalDiff{Float64,Float64}(1.0), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, frac_diff)
    bind!(g, frac_diff, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    run!(exe, start, stop)

    # For order 1, we expect first differences
    expected = [2.0, 3.0, 4.0, 5.0]
    @test output.operation.buffer ≈ expected
end

@testitem "order=0 (Identity)" begin
    using Dates
    
    g = StreamGraph()

    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, 1), 1.0),
        (DateTime(2000, 1, 2), 2.0),
        (DateTime(2000, 1, 3), 3.0),
        (DateTime(2000, 1, 4), 4.0),
        (DateTime(2000, 1, 5), 5.0),
    ]

    values = source!(g, :values, HistoricIterable(Float64, values_data))
    frac_diff = op!(g, :frac_diff, FractionalDiff{Float64,Float64}(0.0), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, frac_diff)
    bind!(g, frac_diff, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    run!(exe, start, stop)

    # For order 0, we expect the original values
    expected = [1.0, 2.0, 3.0, 4.0, 5.0]
    @test output.operation.buffer ≈ expected
end
