@testitem "node accessors" begin
    using Dates

    g = StreamGraph()

    values = source!(g, :values, out=Float64, init=0.0)
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

# @testitem "reset!" begin
#     using Dates

#     g = StreamGraph()

#     values = source!(g, :values, out=Float64, init=0.0)
#     output = sink!(g, :output, Buffer{Int}(min_count=1))

#     reset!(g)
# end
