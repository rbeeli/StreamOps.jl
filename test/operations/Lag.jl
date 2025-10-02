@testitem "reset!" begin
	op = Lag{Int}()
	@test !is_valid(op)

	op(nothing, 1)
	op(nothing, 2)

	@test is_valid(op)
	reset!(op)
	@test !is_valid(op)
end

@testitem "Default lag (lag=1)" begin
	using Dates

	g = StreamGraph()

	values_data = Tuple{DateTime,Int}[
		(DateTime(2000, 1, 1), 1),
		(DateTime(2000, 1, 2), 2),
		(DateTime(2000, 1, 3), 3),
		(DateTime(2000, 1, 4), 4),
		(DateTime(2000, 1, 5), 5),
	]
	values = source!(g, :values, HistoricIterable(Int, values_data))
	lag_op = op!(g, :lag, Lag{Int}(), out = Int)
	output = sink!(g, :output, Buffer{Int}())

	bind!(g, values, lag_op)
	bind!(g, lag_op, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 5)
	run!(exe, start, stop)
	@test output.operation.buffer == [1, 2, 3, 4]
end

@testitem "Custom lag (lag=2)" begin
	using Dates

	g = StreamGraph()

	values_data = Tuple{DateTime,Int}[
		(DateTime(2000, 1, 1), 1),
		(DateTime(2000, 1, 2), 2),
		(DateTime(2000, 1, 3), 3),
		(DateTime(2000, 1, 4), 4),
		(DateTime(2000, 1, 5), 5),
	]
	values = source!(g, :values, HistoricIterable(Int, values_data))
	lag_op = op!(g, :lag, Lag{Int}(2), out = Int)
	output = sink!(g, :output, Buffer{Int}())

	bind!(g, values, lag_op)
	bind!(g, lag_op, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 5)
	run!(exe, start, stop)
	@test output.operation.buffer == [1, 2, 3]
end

@testitem "Zero lag (lag=0)" begin
	using Dates

	g = StreamGraph()

	values_data = Tuple{DateTime,Int}[
		(DateTime(2000, 1, 1), 1),
		(DateTime(2000, 1, 2), 2),
		(DateTime(2000, 1, 3), 3),
		(DateTime(2000, 1, 4), 4),
		(DateTime(2000, 1, 5), 5),
	]
	values = source!(g, :values, HistoricIterable(Int, values_data))
	lag_op = op!(g, :lag, Lag{Int}(0), out = Int)
	output = sink!(g, :output, Buffer{Int}())

	bind!(g, values, lag_op)
	bind!(g, lag_op, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 5)
	run!(exe, start, stop)
	@test output.operation.buffer == [1, 2, 3, 4, 5]
end

@testitem "Invalid lag (negative)" begin
	@test_throws AssertionError Lag{Int}(-1)
end
