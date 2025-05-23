@testitem "copy=false(default)" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, WindowBuffer{Int}(3), out=AbstractVector{Int})

    @test !rolling.operation.copy
    @test is_valid(values.operation) # != nothing -> is_valid
    @test !is_valid(rolling.operation)

    output = sink!(g, :output, Buffer{AbstractVector{Int}}())

    bind!(g, values, rolling)
    bind!(g, rolling, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ])
    ])
    run!(exe, start, stop)

    # all the same values since it's a view into the buffer
    @test output.operation.buffer[1] == [2, 3, 4]
    @test output.operation.buffer[2] == [2, 3, 4]
    @test length(output.operation.buffer) == 2

	@test is_valid(rolling.operation)
	reset!(rolling.operation)
	@test !is_valid(rolling.operation)
end

@testitem "copy=true" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, WindowBuffer{Int}(3; copy=true), out=Vector{Int})

    @test rolling.operation.copy
    @test is_valid(values.operation) # != nothing -> is_valid
    @test !is_valid(rolling.operation)

    output = sink!(g, :output, Buffer{Vector{Int}}())

    bind!(g, values, rolling)
    bind!(g, rolling, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 4)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1), 1),
            (DateTime(2000, 1, 2), 2),
            (DateTime(2000, 1, 3), 3),
            (DateTime(2000, 1, 4), 4)
        ])
    ])
    run!(exe, start, stop)

    @test output.operation.buffer[1] == [1, 2, 3]
    @test output.operation.buffer[2] == [2, 3, 4]
    @test length(output.operation.buffer) == 2
end
