@testitem "full_only=false(default)" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    med = op!(g, :med, Median{Int,Float64}(3), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, med)
    bind!(g, med, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4),
            (DateTime(2000, 1, 5), 1)
        ])
    ])
    run!(exe, start, stop)
    # windows:
    # [1] median=1
    # [1,2] median=(1+2)/2=1.5
    # [1,2,3] median=2
    # [2,3,4] median=3
    # [3,4,1] median=3 (sorted: [1,3,4])
    @test output.operation.buffer ≈ [1.0, 1.5, 2.0, 3.0, 3.0]
end

@testitem "full_only=true" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    med = op!(g, :med, Median{Int,Float64}(3; full_only=true), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, med)
    bind!(g, med, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 5)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4),
            (DateTime(2000, 1, 5), 1)
        ])
    ])
    run!(exe, start, stop)
    # full windows of size 3:
    # [1,2,3] median=2
    # [2,3,4] median=3
    # [3,4,1] median=3
    @test output.operation.buffer ≈ [2, 3, 3]
end
