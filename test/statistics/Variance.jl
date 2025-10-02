@testitem "reset!" begin
    op = Variance{Float64,Float64}(3)

    @test !is_valid(op)

    op(nothing, 1.0)
    op(nothing, 2.0)
    op(nothing, 3.0)

    @test is_valid(op)
    reset!(op)
    @test !is_valid(op)
end

@testitem "window_size=5 corrected=true(default)" begin
    using Dates
    using Statistics

    window_size = 5

    g = StreamGraph()

    vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, i), x)
        for (i, x) in enumerate(vals)
    ]

    values = source!(g, :values, HistoricIterable(Float64, values_data))
    avg = op!(g, :avg, Variance{Float64,Float64}(window_size), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    run!(exe, start, stop)
    for i in window_size:length(vals)
        @test output.operation.buffer[i-window_size+1] ≈ var(vals[i-window_size+1:i], corrected=true)
    end
end

@testitem "window_size=3 corrected=false" begin
    using Dates
    using Statistics

    window_size = 3

    g = StreamGraph()

    vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, i), x)
        for (i, x) in enumerate(vals)
    ]

    values = source!(g, :values, HistoricIterable(Float64, values_data))
    avg = op!(g, :avg, Variance{Float64,Float64}(window_size, corrected=false), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    run!(exe, start, stop)
    for i in window_size:length(vals)
        @test output.operation.buffer[i-window_size+1] ≈ var(vals[i-window_size+1:i], corrected=false)
    end
end

@testitem "window_size=3 corrected=false w/ all constant values" begin
    using Dates

    window_size = 3

    g = StreamGraph()

    vals = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, i), x)
        for (i, x) in enumerate(vals)
    ]
    expected = [0.0, 0.0, 0.0, 0.0, 0.0]

    values = source!(g, :values, HistoricIterable(Float64, values_data))
    avg = op!(g, :avg, Variance{Float64,Float64}(window_size, corrected=false), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    run!(exe, start, stop)

    @test length(output.operation.buffer) == length(expected)
    @test output.operation.buffer ≈ expected
end

@testitem "window_size=5 corrected=true(default) std=true" begin
    using Dates
    using Statistics

    window_size = 5

    g = StreamGraph()

    vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
    values_data = Tuple{DateTime,Float64}[
        (DateTime(2000, 1, i), x)
        for (i, x) in enumerate(vals)
    ]

    values = source!(g, :values, HistoricIterable(Float64, values_data))
    avg = op!(g, :avg, Variance{Float64,Float64}(window_size, std=true), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    run!(exe, start, stop)
    for i in window_size:length(vals)
        @test output.operation.buffer[i-window_size+1] ≈ std(vals[i-window_size+1:i], corrected=true)
    end
end
