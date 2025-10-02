@testitem "default" begin
	using Dates

	g = StreamGraph()

	input = Tuple{DateTime, Int}[
		(DateTime(2000, 1, 1), 1),
		(DateTime(2000, 1, 2), 2),
		(DateTime(2000, 1, 3), 3),
		(DateTime(2000, 1, 4), 4),
	]
	values = source!(g, :values, HistoricIterable(Int, input))
	buffer = sink!(g, :buffer, TimeTupleBuffer{DateTime, Int}())
	@test buffer.operation.min_count == 0
	bind!(g, values, buffer)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 4)
	run!(exe, start, stop)

	actual = get_state(buffer.operation)
	@test length(actual) == 4
	@test all(actual .== input)

	@test is_valid(g[:buffer].operation)
	reset!(g[:buffer].operation)
	@test is_valid(g[:buffer].operation) # min_count=0
end

@testitem "min_count" begin
	using Dates

	g = StreamGraph()

	input = Tuple{DateTime, Int}[
		(DateTime(2000, 1, 1), 1),
		(DateTime(2000, 1, 2), 2),
		(DateTime(2000, 1, 3), 3),
		(DateTime(2000, 1, 4), 4),
	]
	values = source!(g, :values, HistoricIterable(Int, input))
	buffer = op!(g, :buffer, TimeTupleBuffer{DateTime, Int}(min_count = 3))
	output = sink!(g, :output, Counter())
	@test buffer.operation.min_count == 3
	bind!(g, values, buffer)
	bind!(g, buffer, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 4)
	run!(exe, start, stop)

	# output should only be called twice because of min_count=3
	@test get_state(output.operation) == 2

	@test is_valid(g[:buffer].operation)
	reset!(g[:buffer].operation)
	@test !is_valid(g[:buffer].operation) # min_count=3
end

@testitem "w/ flush" begin
	using Dates

	g = StreamGraph()

	# Create source nodes
	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 6)
	timer = source!(g, :timer, HistoricTimer(interval = Day(2), start_time = start))
	input = Tuple{DateTime, Float64}[
		(DateTime(2000, 1, 1), 1.0),
		(DateTime(2000, 1, 2), 2.0),
		(DateTime(2000, 1, 3), 3.0),
		(DateTime(2000, 1, 4), 4.0),
		(DateTime(2000, 1, 5), 5.0),
		(DateTime(2000, 1, 6), 6.0),
	]
	values = source!(g, :values, HistoricIterable(Float64, input))

	# Create operation nodes
	buffer = op!(g, :buffer, TimeTupleBuffer{DateTime, Float64}())
	flush_buffer = op!(g, :flush_buffer, Func{Vector{Tuple{DateTime, Float64}}}((exe, buf, dt) -> begin
				vals = copy(buf)
				empty!(buf)
				vals
			end, Tuple{DateTime, Float64}[]))

	@test buffer.operation.min_count == 0

	# Create sink nodes
	collected = []
	output = sink!(g, :output, Func((exe, x) -> push!(collected, collect(x)), nothing))

	# Create edges between nodes (define the computation graph)
	bind!(g, values, buffer)
	bind!(g, buffer, flush_buffer; call_policies = [Never()])
	bind!(g, timer, flush_buffer)
	bind!(g, flush_buffer, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	run!(exe, start, stop)
	@test collected[1] == Tuple{DateTime, Float64}[]
	@test collected[2] == input[1:2]
	@test collected[3] == input[3:4]
	@test length(collected) == 3
end
