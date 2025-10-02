@testitem "@sink without binding" begin
    g = StreamGraph()

    dest = @sink g :collector Print()

    collector = get_node(g, :collector)

    @test dest == :collector
    @test is_sink(collector)
    @test isempty(collector.input_bindings)
end

@testitem "@sink with binding keywords" begin
    using Dates

    g = StreamGraph()

    source!(g, :values, HistoricIterable(Float64, Tuple{DateTime,Float64}[]))
    dest = @sink g :values => :collector Print() call_policies=[Never()]

    collector = get_node(g, :collector)
    binding = only(collector.input_bindings)

    @test dest == :collector
    @test binding.input_nodes == [get_node(g, :values)]
    @test binding.call_policies == [Never()]
end

@testitem "@op without binding" begin
    g = StreamGraph()

    dest = @op g :transform Func((exe, value) -> value, 0.0)

    node = get_node(g, :transform)

    @test dest == :transform
    @test !is_sink(node)
    @test !is_source(node)
    @test node.output_type === Float64
    @test node.operation isa Func
end

@testitem "@op tuple binding forwards keywords" begin
    using Dates

    g = StreamGraph()

    source!(g, :a, HistoricIterable(Int, Tuple{DateTime,Int}[]))
    source!(g, :b, HistoricIterable(Int, Tuple{DateTime,Int}[]))
    dest = @op g (:a, :b) => :sum Func((exe, x, y) -> x + y, 0) call_policies=[IfExecuted(:all)] bind_as=TupleParams()

    node = get_node(g, :sum)
    binding = only(node.input_bindings)
    policy = only(binding.call_policies)

    @test dest == :sum
    @test binding.input_nodes == [get_node(g, :a), get_node(g, :b)]
    @test policy isa IfExecuted
    @test policy.nodes == :all
    @test binding.bind_as isa TupleParams
end

@testitem "@bind tuple sources" begin
    using Dates

    g = StreamGraph()

    source!(g, :lhs, HistoricIterable(Float64, Tuple{DateTime,Float64}[]))
    source!(g, :rhs, HistoricIterable(Float64, Tuple{DateTime,Float64}[]))
    @sink g :collector Print()

    dest = @bind g (:lhs, :rhs) => :collector call_policies=[IfValid(:all)] bind_as=TupleParams()

    collector = get_node(g, :collector)
    binding = only(collector.input_bindings)
    policy = only(binding.call_policies)

    @test dest == :collector
    @test binding.input_nodes == [get_node(g, :lhs), get_node(g, :rhs)]
    @test policy isa IfValid
    @test policy.nodes == :all
    @test binding.bind_as isa TupleParams
end
