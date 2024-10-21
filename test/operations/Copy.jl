@testitem "Copy{Vector{Int}}()" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Vector{Int}, init=Int[])
    buffer = op!(g, :buffer, Copy{Vector{Int}}(), out=Vector{Int})
    output = sink!(g, :output, Buffer{Vector{Int}}())

    bind!(g, values, buffer)
    bind!(g, buffer, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    input = [1,2,3]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), input)
        ])
    ])
    run!(exe, start, stop)
    @test output.operation.buffer[1] == input # same contents
    @test output.operation.buffer[1] !== input # different objects (copy)
end

@testitem "Copy(Int[])" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Vector{Int}, init=Int[])
    buffer = op!(g, :buffer, Copy(Int[]), out=Vector{Int})
    output = sink!(g, :output, Buffer{Vector{Int}}())

    bind!(g, values, buffer)
    bind!(g, buffer, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    input = [1,2,3]

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), input)
        ])
    ])
    run!(exe, start, stop)
    @test output.operation.buffer[1] == input # same contents
    @test output.operation.buffer[1] !== input # different objects (copy)
end
