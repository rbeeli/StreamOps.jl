using Test
using Dates
using StreamOps

@testset verbose = true "call policies" begin

    @testset "default policies single input" begin
        g = StreamGraph()

        source!(g, :timer, out=DateTime, init=DateTime(0))

        op!(g, :never_valid, Func((exe, v) -> v, DateTime(0), is_valid=x -> false), out=DateTime)
        bind!(g, :timer, :never_valid)

        sink!(g, :output, Buffer{DateTime}())
        bind!(g, :never_valid, :output)

        # check default call policies
        @test length(g[:output].input_bindings[1].call_policies) == 2
        @test g[:output].input_bindings[1].call_policies[1] isa IfExecuted
        @test g[:output].input_bindings[1].call_policies[2] isa IfValid
    end

    @testset "default policies multi-input" begin
        g = StreamGraph()

        source!(g, :timer, out=DateTime, init=DateTime(0))

        op!(g, :never_valid, Func((exe, v) -> v, DateTime(0), is_valid=x -> false), out=DateTime)
        bind!(g, :timer, :never_valid)

        sink!(g, :output, Buffer{Tuple{DateTime,DateTime}}())
        bind!(g, (:timer, :never_valid), :output, bind_as=TupleParams())

        # check default call policies
        @test length(g[:output].input_bindings[1].call_policies) == 2
        @test g[:output].input_bindings[1].call_policies[1] isa IfExecuted
        @test g[:output].input_bindings[1].call_policies[2] isa IfValid
    end

    @testset "IfValid (never valid)" begin
        g = StreamGraph()

        source!(g, :timer, out=DateTime, init=DateTime(0))

        op!(g, :never_valid, Func((exe, v) -> v, DateTime(0), is_valid=x -> false), out=DateTime)
        bind!(g, :timer, :never_valid)

        sink!(g, :output, Buffer{DateTime}())
        bind!(g, :never_valid, :output, call_policies=IfValid(:all))

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        set_adapters!(exe, [
            HistoricTimer{DateTime}(exe, g[:timer]; interval=Day(1), start_time=start)
        ])
        run!(exe, start, stop)

        buffer = g[:output].operation.buffer
        @test length(buffer) == 0
    end

    @testset "IfValid(:a, :b)" begin
        g = StreamGraph()

        source!(g, :a, out=Union{Nothing,Int}, init=nothing)
        source!(g, :b, out=Union{Nothing,Int}, init=nothing)

        sink!(g, :output, Buffer{NTuple{2,Int}}())
        bind!(g, (:a, :b), :output, call_policies=IfValid(:a, :b), bind_as=TupleParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        set_adapters!(exe, [
            HistoricIterable(exe, g[:a], [
                (DateTime(2000, 1, 1), nothing),
                (DateTime(2000, 1, 2), nothing),
                (DateTime(2000, 1, 3), nothing),
                (DateTime(2000, 1, 4), 4)
            ])
            HistoricIterable(exe, g[:b], [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), nothing),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4)
            ])
        ])
        run!(exe, start, stop)

        buffer = g[:output].operation.buffer
        @test length(buffer) == 2
        @test buffer[1] == (4, 3)
        @test buffer[2] == (4, 4)
    end

    @testset "IfValid(:all)" begin
        g = StreamGraph()

        source!(g, :a, out=Union{Nothing,Int}, init=nothing)
        source!(g, :b, out=Union{Nothing,Int}, init=nothing)

        sink!(g, :output, Buffer{NTuple{2,Int}}())
        bind!(g, (:a, :b), :output, call_policies=IfValid(:all), bind_as=TupleParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        set_adapters!(exe, [
            HistoricIterable(exe, g[:a], [
                (DateTime(2000, 1, 1), nothing),
                (DateTime(2000, 1, 2), nothing),
                (DateTime(2000, 1, 3), nothing),
                (DateTime(2000, 1, 4), 4)
            ])
            HistoricIterable(exe, g[:b], [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), nothing),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4)
            ])
        ])
        run!(exe, start, stop)

        buffer = g[:output].operation.buffer
        @test length(buffer) == 2
        @test buffer[1] == (4, 3)
        @test buffer[2] == (4, 4)
    end

    @testset "IfValid(:any)" begin
        g = StreamGraph()

        source!(g, :a, out=Union{Nothing,Int}, init=nothing)
        source!(g, :b, out=Union{Nothing,Int}, init=nothing)

        sink!(g, :output, Buffer{NTuple{2,Union{Nothing,Int}}}())
        bind!(g, (:a, :b), :output, call_policies=IfValid(:any), bind_as=TupleParams())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 4)
        set_adapters!(exe, [
            HistoricIterable(exe, g[:a], [
                (DateTime(2000, 1, 1), nothing),
                (DateTime(2000, 1, 2), nothing),
                (DateTime(2000, 1, 3), nothing),
                (DateTime(2000, 1, 4), 4)
            ])
            HistoricIterable(exe, g[:b], [
                (DateTime(2000, 1, 1), 1),
                (DateTime(2000, 1, 2), nothing),
                (DateTime(2000, 1, 3), 3),
                (DateTime(2000, 1, 4), 4)
            ])
        ])
        run!(exe, start, stop)

        buffer = g[:output].operation.buffer
        
        @test length(buffer) == 5
        @test buffer[1] == (nothing, 1)
        @test buffer[2] == (nothing, 1)
        @test buffer[3] == (nothing, 3)
        @test buffer[4] == (4, 3)
        @test buffer[5] == (4, 4)
    end

    @testset "IfInvalid (never valid)" begin
        g = StreamGraph()

        source!(g, :timer, out=DateTime, init=DateTime(0))

        op!(g, :never_valid, Func((exe, v) -> NaN, NaN, is_valid=x -> false), out=Float64)
        bind!(g, :timer, :never_valid)

        sink!(g, :output, Buffer{Float64}())
        bind!(g, :never_valid, :output, call_policies=IfInvalid())

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        set_adapters!(exe, [
            HistoricTimer{DateTime}(exe, g[:timer]; interval=Day(1), start_time=start)
        ])
        run!(exe, start, stop)

        buffer = g[:output].operation.buffer
        
        @test length(buffer) == 3
        @test all(isnan.(buffer))
    end

    @testset "IfSource(:timer1)" begin
        g = StreamGraph()

        source!(g, :timer1, out=DateTime, init=DateTime(0))
        source!(g, :timer2, out=DateTime, init=DateTime(0))

        op!(g, :call_if_1, Func((exe, dt1, dt2) -> (dt1, dt2), (DateTime(0), DateTime(0))), out=NTuple{2,DateTime})
        bind!(g, (:timer1, :timer2), :call_if_1, call_policies=IfSource(:timer1))

        sink!(g, :output, Buffer{NTuple{2,DateTime}}())
        bind!(g, :call_if_1, :output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        set_adapters!(exe, [
            HistoricTimer{DateTime}(exe, g[:timer1]; interval=Day(1), start_time=start),
            HistoricTimer{DateTime}(exe, g[:timer2]; interval=Hour(6), start_time=start)
        ])
        run!(exe, start, stop)

        buffer = g[:output].operation.buffer
        
        @test length(buffer) == 3
    end

    @testset "IfExecuted(:any)" begin
        g = StreamGraph()

        source!(g, :timer1, out=DateTime, init=DateTime(0))
        source!(g, :timer2, out=DateTime, init=DateTime(0))

        op!(g, :call_if_1, Func((exe, dt1, dt2) -> (dt1, dt2), (DateTime(0), DateTime(0))), out=NTuple{2,DateTime})
        bind!(g, (:timer1, :timer2), :call_if_1, call_policies=IfExecuted(:any))

        sink!(g, :output, Buffer{NTuple{2,DateTime}}())
        bind!(g, :call_if_1, :output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        set_adapters!(exe, [
            HistoricTimer{DateTime}(exe, g[:timer1]; interval=Day(1), start_time=start),
            HistoricTimer{DateTime}(exe, g[:timer2]; interval=Hour(6), start_time=start)
        ])
        run!(exe, start, stop)

        buffer = g[:output].operation.buffer

        @test length(buffer) == 12
    end

    @testset "IfExecuted(:timer1)" begin
        g = StreamGraph()

        source!(g, :timer1, out=DateTime, init=DateTime(0))
        source!(g, :timer2, out=DateTime, init=DateTime(0))

        op!(g, :call_if_1, Func((exe, dt1, dt2) -> (dt1, dt2), (DateTime(0), DateTime(0))), out=NTuple{2,DateTime})
        bind!(g, (:timer1, :timer2), :call_if_1, call_policies=IfExecuted(:timer1))

        sink!(g, :output, Buffer{NTuple{2,DateTime}}())
        bind!(g, :call_if_1, :output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 3)
        set_adapters!(exe, [
            HistoricTimer{DateTime}(exe, g[:timer1]; interval=Day(1), start_time=start),
            HistoricTimer{DateTime}(exe, g[:timer2]; interval=Hour(6), start_time=start)
        ])
        run!(exe, start, stop)

        buffer = g[:output].operation.buffer
        
        @test length(buffer) == 3
    end

end
