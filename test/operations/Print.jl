@testitem "default" begin
	using Dates
	using Suppressor

	g = StreamGraph()

	values_data = Tuple{DateTime,Int}[
		(DateTime(2000, 1, 1), 1),
		(DateTime(2000, 1, 2), 2),
		(DateTime(2000, 1, 3), 3),
		(DateTime(2000, 1, 4), 4),
	]
	values = source!(g, :values, HistoricIterable(Int, values_data))
	buffer = sink!(g, :buffer, Print())

	bind!(g, values, buffer)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 4)
	output = @capture_out begin
		run!(exe, start, stop)
	end
	@test output == "1\n2\n3\n4\n"

	reset!(buffer.operation)
end

@testitem "custom fn" begin
	using Dates
	using Suppressor

	g = StreamGraph()

	values_data = Tuple{DateTime,Int}[
		(DateTime(2000, 1, 1), 1),
		(DateTime(2000, 1, 2), 2),
		(DateTime(2000, 1, 3), 3),
		(DateTime(2000, 1, 4), 4),
	]
	values = source!(g, :values, HistoricIterable(Int, values_data))
	buffer = sink!(g, :buffer, Print((exe, x) -> println("x=$x")))

	bind!(g, values, buffer)

	states = compile_graph!(DateTime, g)
	exe = HistoricExecutor{DateTime}(g, states)
	setup!(exe)

	start = DateTime(2000, 1, 1)
	stop = DateTime(2000, 1, 4)
	output = @capture_out begin
		run!(exe, start, stop)
	end
	@test output == "x=1\nx=2\nx=3\nx=4\n"
end
