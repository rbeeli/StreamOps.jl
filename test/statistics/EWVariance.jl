@testitem "reset!" begin
    op = EWVariance{Float64,Float64}(alpha=0.9, corrected=false)

    op(nothing, 1.0)
    op(nothing, 2.0)
    op(nothing, 3.0)

    @test is_valid(op)
    reset!(op)
    @test !is_valid(op)
end

@testitem "alpha=0.9 corrected=false" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, EWVariance{Float64,Float64}(alpha=0.9, corrected=false), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    # Reference values generated by pandas, see ./EWVariance.py
    expected = [
        0.00000000
        211.70250000
        23.65087500
        2.87274375
        4.40310094
        2088.66754336
        25946.74390167
    ]
    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    run!(exe, start, stop)

    @test output.operation.buffer ≈ expected
end

@testitem "alpha=0.9 corrected=false std=true" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, EWVariance{Float64,Float64}(alpha=0.9, corrected=false, std=true), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    # Reference values generated by pandas, see ./EWVariance.py
    expected = sqrt.([
        0.00000000
        211.70250000
        23.65087500
        2.87274375
        4.40310094
        2088.66754336
        25946.74390167
    ])
    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    run!(exe, start, stop)

    @test output.operation.buffer ≈ expected
end

@testitem "alpha=0.9 corrected=true" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, EWVariance{Float64,Float64}(alpha=0.9, corrected=true), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    # Reference values generated by pandas, see ./EWVariance.py
    expected = [
        NaN
        1176.125000000000
        118.379954954955
        14.638763268219
        24.068882923978
        11487.746845379137
        142707.147689443314
    ]
    vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    run!(exe, start, stop)

    # uninitialized value is 0
    @test output.operation.buffer[1] == 0
    @test output.operation.buffer[2:end] ≈ expected[2:end]
end

@testitem "alpha=0.9 corrected=false (constant numbers)" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, EWVariance{Float64,Float64}(alpha=0.9, corrected=false), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    expected = [0.0, 0.0, 0.0]
    vals = [1.0, 1.0, 1.0]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    run!(exe, start, stop)

    @test output.operation.buffer ≈ expected
end

@testitem "alpha=0.9 corrected=true w/ all constant values" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
    avg = op!(g, :avg, EWVariance{Float64,Float64}(alpha=0.9, corrected=true), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, avg)
    bind!(g, avg, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    expected = [0.0, 0.0, 0.0]
    vals = [1.0, 1.0, 1.0]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, i), x)
            for (i, x) in enumerate(vals)
        ])
    ])
    run!(exe, start, stop)

    # uninitialized value is 0
    @test output.operation.buffer[1] == 0
    @test output.operation.buffer[2:end] ≈ expected[2:end]
end
