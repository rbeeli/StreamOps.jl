@testitem "default ctor (incl. reset!)" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    cumsum = op!(g, :cumsum, CumSum{Int,Float64}(), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, cumsum)
    bind!(g, cumsum, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    vals = [1, 2, 3, 4, 5]
    expected = [1.0, 3.0, 6.0, 10.0, 15.0]

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

    reset!(g[:cumsum].operation)
    @test get_state(g[:cumsum].operation) == 0
end

@testitem "custom init value" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    cumsum = op!(g, :cumsum, CumSum{Int,Float64}(init=100.0), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, cumsum)
    bind!(g, cumsum, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    vals = [1, 2, 3, 4, 5]
    expected = [101.0, 103.0, 106.0, 110.0, 115.0]

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

@testitem "init_valid=true" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    cumsum = op!(g, :cumsum, CumSum{Int,Float64}(init=100.0, init_valid=true), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, cumsum)
    bind!(g, cumsum, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    # Test initial validity
    @test is_valid(cumsum.operation)
    @test get_state(cumsum.operation) == 100.0

    vals = [1, 2, 3, 4, 5]
    expected = [101.0, 103.0, 106.0, 110.0, 115.0]

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

@testitem "reset!" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    cumsum = op!(g, :cumsum, CumSum{Int,Float64}(init=100.0), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, values, cumsum)
    bind!(g, cumsum, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    vals = [1, 2, 3]
    expected = [101.0, 103.0, 106.0]

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

    # Test reset
    reset!(cumsum.operation)
    @test !is_valid(cumsum.operation)
    @test get_state(cumsum.operation) == 100.0
end
