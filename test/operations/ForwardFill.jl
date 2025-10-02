@testitem "reset!" begin
	op = ForwardFill{Float64}()
	@test !is_valid(op)

	op(nothing, 1.0)

	@test is_valid(op)
	reset!(op)
	@test !is_valid(op)
end

@testitem "default ctor (missing, NaN filled)" begin
	using Dates

	g = StreamGraph()

	vals = [1.0, NaN, 2.0, -1.0, NaN, NaN, 3.0, NaN, 4.0, missing]
	values_data = Tuple{DateTime,Union{Missing,Float64}}[
		(DateTime(2000, 1, i), x)
		for (i, x) in enumerate(vals)
	]
	values = source!(g, :values, HistoricIterable(Union{Missing,Float64}, values_data))
	ffill = op!(g, :ffill, ForwardFill{Float64}())
	output = sink!(g, :output, Buffer{Float64}())

	bind!(g, values, ffill)
	bind!(g, ffill, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	expected = [1.0, 1.0, 2.0, -1.0, -1.0, -1.0, 3.0, 3.0, 4.0, 4.0]

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, length(vals))

	run!(exe, start, stop)
	@test output.operation.buffer == expected
end

@testitem "default ctor (missing, NaN filled) w/ string type" begin
	using Dates

	g = StreamGraph()

	vals = ["a", missing, "", "c", missing, missing, "d", missing, "e", missing]
	values_data = Tuple{DateTime,Union{Missing,String}}[
		(DateTime(2000, 1, i), x)
		for (i, x) in enumerate(vals)
	]
	values = source!(g, :values, HistoricIterable(Union{Missing,String}, values_data))
	ffill = op!(g, :ffill, ForwardFill{String}())
	output = sink!(g, :output, Buffer{String}())

	bind!(g, values, ffill)
	bind!(g, ffill, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	expected = ["a", "a", "a", "c", "c", "c", "d", "d", "e", "e"]

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, length(vals))

	run!(exe, start, stop)
	@test output.operation.buffer == expected
end

@testitem "should_fill_fn=<fn>, init=99, first invalid" begin
	using Dates

	g = StreamGraph()

	vals = [0, 1, 3, 0, -2, 4, 3]
	values_data = Tuple{DateTime,Int}[
		(DateTime(2000, 1, i), x)
		for (i, x) in enumerate(vals)
	]
	values = source!(g, :values, HistoricIterable(Int, values_data))
	ffill = op!(g, :ffill, ForwardFill{Int}(x -> x == 0, init = 99))
	output = sink!(g, :output, Buffer{Int}())

	bind!(g, values, ffill)
	bind!(g, ffill, output)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	expected = [99, 1, 3, 3, -2, 4, 3]

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, length(vals))

	run!(exe, start, stop)
	@test output.operation.buffer == expected
end
