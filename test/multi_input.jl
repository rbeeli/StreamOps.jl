using Test
using Dates
using StreamOps

@testset verbose = true "multi-input bindings" begin

    @testset "NamedParams" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe; values, timer) -> begin
                @assert values isa Float64
                @assert timer isa DateTime
                called += 1
            end), params_bind=NamedParams())

        bind!(g, timer, output, call_policies=[Always()])
        bind!(g, values, output, call_policies=[Always()])

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            TimerAdapter{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 6 # 3 values * 2 sources
    end

    @testset "PositionParams" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe, a, b) -> begin
                @assert a isa DateTime
                @assert b isa Float64
                called += 1
            end), params_bind=PositionParams())

        bind!(g, timer, output, call_policies=[Always()])
        bind!(g, values, output, call_policies=[Always()])

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            TimerAdapter{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 6 # 3 values * 2 sources
    end

    @testset "TupleParams" begin
        g = StreamGraph()

        timer = source!(g, :timer, out=DateTime, init=DateTime(0))
        values = source!(g, :values, out=Float64, init=0.0)

        called = 0
        output = sink!(g, :output, Func((exe, params) -> begin
                @assert params isa Tuple{DateTime,Float64}
                called += 1
            end), params_bind=TupleParams())

        bind!(g, timer, output, call_policies=[Always()])
        bind!(g, values, output, call_policies=[Always()])

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        adapters = [
            TimerAdapter{DateTime}(exe, timer; interval=Dates.Day(1), start_time=start),
            IterableAdapter(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 4.0),
            ]),
        ]
        run_simulation!(exe, adapters, start, stop)

        @test called == 6 # 3 values * 2 sources
    end

end
