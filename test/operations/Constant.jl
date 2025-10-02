@testitem "reset!" begin
    op = Constant(999)
    @test is_valid(op)

    op(nothing, 1.0)

    @test is_valid(op)
    reset!(op)
    @test is_valid(op)
end

@testitem "integer with input binding" begin
    using Dates

    g = StreamGraph()

    vals = [2, 3, -1, 0, 3]
    values_data = Tuple{DateTime,Int}[(DateTime(2000, 1, i), x) for (i, x) in enumerate(vals)]

    source!(g, :values, HistoricIterable(Int, values_data))
    op!(g, :constant, Constant(999))
    sink!(g, :output, Buffer{Int}())

    bind!(g, :values, :constant)
    bind!(g, :constant, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    run!(exe, start, stop)

    @test g[:output].operation.buffer == [999, 999, 999, 999, 999]
end

@testitem "integer w/o input binding (source node)" begin
    using Dates

    g = StreamGraph()

    vals = [2, 3, -1, 0, 3]
    values_data = Tuple{DateTime,Int}[(DateTime(2000, 1, i), x) for (i, x) in enumerate(vals)]

    source!(g, :values, HistoricIterable(Int, values_data))
    op!(g, :constant, Constant(999))
    sink!(g, :output, Buffer{Int}())

    bind!(g, :constant, :output)
    bind!(g, :values, :output; bind_as=NoBind())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    run!(exe, start, stop)

    @test g[:output].operation.buffer == [999, 999, 999, 999, 999]
end

@testitem "integer with input trigger but no binding" begin
    using Dates

    g = StreamGraph()

    vals = [2, 3, -1, 0, 3]
    values_data = Tuple{DateTime,Int}[(DateTime(2000, 1, i), x) for (i, x) in enumerate(vals)]

    source!(g, :values, HistoricIterable(Int, values_data))
    op!(g, :constant, Constant(999))
    sink!(g, :output, Buffer{Int}())

    bind!(g, :values, :constant; bind_as=NoBind())
    bind!(g, :constant, :output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, length(vals))
    run!(exe, start, stop)

    @test g[:output].operation.buffer == [999, 999, 999, 999, 999]
end

# @testitem "constant as invalid fallback value" begin
# using Dates

#     g = StreamGraph()

#     values = source!(g, :values)
#     constant = op!(g, :constant, Constant(9.9))
#     mean = op!(g, :mean, Mean{Int,Float64}(3; full_only=true)) # only valid with 3+ values
#     output = sink!(g, :output, Buffer{Float64}())

#     bind!(g, values, mean)
#     bind!(g, mean, output)
#     bind!(g, constant, output, call_policies=IfInvalid(:mean))

#     states = compile_graph!(DateTime, g)
#     exe = HistoricExecutor{DateTime}(g, states)
#     setup!(exe)

#     vals = [2, 3, -1, 0, 3]
#     start = DateTime(2000, 1, 1)
#     stop = DateTime(2000, 1, length(vals))
#     set_adapters!(exe, [
#         HistoricIterable(exe, values, [
#             (DateTime(2000, 1, i), x)
#             for (i, x) in enumerate(vals)
#         ])
#     ])
#     run!(exe, start, stop)

#     println(output.operation.buffer)
#     # @test output.operation.buffer == [999, 999, 999, 999, 999]
# end
