@testitem "reset!" begin
	op = Copy{Vector{Int}}()
	@test !is_valid(op)

	op(nothing, [1.0])

	@test is_valid(op)
	reset!(op)
	@test !is_valid(op)
end

@testitem "Copy{Vector{Int}}()" begin
	using Dates

	g = StreamGraph()

	input = [1, 2, 3]
	values_data = Tuple{DateTime,Vector{Int}}[(DateTime(2000, 1, 1), input)]
	values = source!(g, :values, HistoricIterable(Vector{Int}, values_data))
	buffer = op!(g, :buffer, Copy{Vector{Int}}())
	output = sink!(g, :output, Buffer{Vector{Int}}())

	bind!(g, values, buffer)
	bind!(g, buffer, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 4)
	run!(exe, start, stop)
	@test output.operation.buffer[1] == input # same contents
	@test output.operation.buffer[1] !== input # different objects (copy)
end

@testitem "Copy(Int[])" begin
	using Dates

	g = StreamGraph()

	input = [1, 2, 3]
	values_data = Tuple{DateTime,Vector{Int}}[(DateTime(2000, 1, 1), input)]
	values = source!(g, :values, HistoricIterable(Vector{Int}, values_data))
	buffer = op!(g, :buffer, Copy(Int[]))
	output = sink!(g, :output, Buffer{Vector{Int}}())

	bind!(g, values, buffer)
	bind!(g, buffer, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 4)
	run!(exe, start, stop)
	@test output.operation.buffer[1] == input # same contents
	@test output.operation.buffer[1] !== input # different objects (copy)
end
