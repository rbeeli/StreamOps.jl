@testitem "defaults" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, TimeMean{DateTime,Int,Float64}(Minute(2), :closed), out=Float64)

    # empty by default valid with value "empty_value=NaN"
    @test is_valid(rolling.operation)
    @test isnan(get_state(rolling.operation))
end

@testitem "empty_valid=false" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, TimeMean{DateTime,Int,Float64}(Minute(2), :closed, empty_valid=false), out=Float64)

    @test !is_valid(rolling.operation)
end

@testitem "rolling mean with gaps" begin
    using Dates
    
    g = StreamGraph()

    values = source!(g, :values, out=Int, init=0)
    rolling = op!(g, :rolling, TimeMean{DateTime,Int,Float64}(Minute(2), :closed), out=Float64)

    @test is_valid(values.operation)

    # empty by default valid with value "empty_value=NaN"
    @test is_valid(rolling.operation)
    @test isnan(get_state(rolling.operation))

    output = sink!(g, :output, Buffer{Float64}())
    bind!(g, values, rolling)
    bind!(g, rolling, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1, 0, 0, 0)
    stop = DateTime(2000, 1, 1, 0, 10, 0)
    set_adapters!(exe, [
        HistoricIterable(exe, values, [
            (DateTime(2000, 1, 1, 0, 0, 0), 1),
            (DateTime(2000, 1, 1, 0, 1, 0), 2),
            (DateTime(2000, 1, 1, 0, 2, 0), 3),
            (DateTime(2000, 1, 1, 0, 3, 0), 4),
            (DateTime(2000, 1, 1, 0, 10, 0), 10)
        ])
    ])
    run!(exe, start, stop)

    # values right on the cutoff time are included
    @test output.operation.buffer[1] == sum([1]) / 1.0
    @test output.operation.buffer[2] == sum([1, 2]) / 2.0
    @test output.operation.buffer[3] == sum([1, 2, 3]) / 3.0
    @test output.operation.buffer[4] == sum([2, 3, 4]) / 3.0
    @test output.operation.buffer[5] == sum([10]) / 1.0
    @test length(output.operation.buffer) == 5
end

@testitem "use timer to fetch value" begin
    using Dates
    
    g = StreamGraph()

    source!(g, :timer, out=DateTime, init=DateTime(0))
    source!(g, :values, out=Int, init=0)

    op!(g, :rolling, TimeMean{DateTime,Int,Float64}(Day(2), :closed), out=Float64)
    bind!(g, :values, :rolling)

    @test is_valid(g[:values].operation)

    # empty by default valid with value "empty_value=NaN"
    @test is_valid(g[:rolling].operation)
    @test isnan(get_state(g[:rolling].operation))

    output = sink!(g, :output, Buffer{Tuple{DateTime,Float64}}())
    bind!(g, (:timer, :rolling), :output, call_policies=IfExecuted(:timer), bind_as=TupleParams())

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 8)
    set_adapters!(exe, [
        HistoricTimer{DateTime}(exe, g[:timer]; interval=Day(1), start_time=start),
        HistoricIterable(exe, g[:values], [
            (DateTime("2000-01-01T00:00:00"), 1),
            (DateTime("2000-01-02T00:00:00"), 2),
            (DateTime("2000-01-03T00:00:00"), 3),
            (DateTime("2000-01-04T00:00:00"), 4),
            (DateTime("2000-01-08T00:00:00"), 8)
        ])
    ])
    run!(exe, start, stop)

    buffer = output.operation.buffer
    @test buffer[1][1] == DateTime("2000-01-01T00:00:00")
    @test isnan(buffer[1][2])
    @test buffer[2] == (DateTime("2000-01-02T00:00:00"), 1.0)
    @test buffer[3] == (DateTime("2000-01-03T00:00:00"), 1.5)
    @test buffer[4] == (DateTime("2000-01-04T00:00:00"), 2.5)
    @test buffer[5] == (DateTime("2000-01-05T00:00:00"), 3.5)
    @test buffer[6] == (DateTime("2000-01-06T00:00:00"), 4.0)
    @test buffer[7][1] == DateTime("2000-01-07T00:00:00")
    @test isnan(buffer[7][2])
    @test buffer[8] == (DateTime("2000-01-08T00:00:00"), 8.0)
end
