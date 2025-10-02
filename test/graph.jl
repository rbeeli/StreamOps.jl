@testitem "node accessors" begin
    using Dates

    g = StreamGraph()

    values = source!(g, :values, HistoricIterable(Float64, Tuple{DateTime,Float64}[]))
    output = sink!(g, :output, Print())

    @test get_node(g, :values) == values
    @test get_node(g, :output) == output

    @test g[:values] == values
    @test g[:output] == output

    @test get_node(g, 1) == values
    @test get_node(g, 2) == output

    @test get_node_label(g, 1) == :values
    @test get_node_label(g, 2) == :output
end

@testitem "graph reset!" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, HistoricIterable(Int, Tuple{DateTime,Int}[(DateTime(0), 1)]))
    sink!(g, :collector, Buffer{Int}())
    bind!(g, :values, :collector)

    states = compile_graph!(DateTime, g)

    states.values.last_value[] = 42
    states.values.has_value = true
    states.collector(nothing, 7)
    states.values__time = DateTime(2020, 1, 2)
    states.collector__time = DateTime(2020, 1, 3)
    fill!(states.__executed, true)

    reset!(states)

    @test all(!, states.__executed)
    @test states.values__time == time_zero(DateTime)
    @test states.collector__time == time_zero(DateTime)
    @test !states.values.has_value
    @test isnothing(get_state(states.values))
    @test isempty(states.collector.buffer)
end
