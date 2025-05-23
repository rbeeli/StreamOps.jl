@testitem "reset!" begin
    op = Skewness{Float64,Float64}(5)

    @test !is_valid(op)

    op(nothing, 1.0)
    op(nothing, 2.0)
    op(nothing, 3.0)
    op(nothing, 4.0)
    op(nothing, 5.0)

    @test is_valid(op)
    reset!(op)
    @test !is_valid(op)
end

@testitem "window_size=5" begin
    using Dates

    window_size = 5

    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    skew = op!(g, :skew, Skewness{Float64,Float64}(window_size), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, skew)
    bind!(g, skew, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    # Reference values generated using Python script ./Skewness.py
    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]
    expected = [2.16310746, 2.22811474, -1.64652492]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    run!(exe, start, stop)
    
    @test length(output.operation.buffer) == length(expected)
    @test output.operation.buffer ≈ expected
end

@testitem "window_size=3" begin
    using Dates
    
    window_size = 3

    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    skew = op!(g, :skew, Skewness{Float64,Float64}(window_size), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, skew)
    bind!(g, skew, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    # Reference values generated using Python script ./Skewness.py
    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]
    expected = [1.73165647, 1.60668343, -0.50516543,
        1.71926473, -1.18345510]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    run!(exe, start, stop)
    
    @test length(output.operation.buffer) == length(expected)
    @test output.operation.buffer ≈ expected
end

@testitem "window_size=3 w/ all constant values" begin
    using Dates
    
    window_size = 3

    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    skew = op!(g, :skew, Skewness{Float64,Float64}(window_size), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, skew)
    bind!(g, skew, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    vals = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    expected = [0.0, 0.0, 0.0, 0.0, 0.0]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    run!(exe, start, stop)
    
    @test length(output.operation.buffer) == length(expected)
    @test output.operation.buffer ≈ expected
end
