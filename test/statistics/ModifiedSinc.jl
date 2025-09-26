@testitem "order=1" begin
    using Test

    @test_throws "Order must one of 2, 4, 6, 8, 10" ModifiedSinc{Float64,Float64}(10, 1)
end

@testitem "window_size=0" begin
    using Test

    @test_throws "Window size must be greater than 0" ModifiedSinc{Float64,Float64}(0, 2)
end

@testitem "order=2" begin
    using Dates

    deg = 2

    for window_size in 2:2:10
        g = StreamGraph()
        values = source!(g, :values; out=Float64, init=0.0)
        avg = op!(g, :avg, ModifiedSinc{Float64,Float64}(window_size, deg); out=Float64)
        output = sink!(g, :output, Buffer{Float64}())
        bind!(g, values, avg)
        bind!(g, avg, output)

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

        vals = Float64[1, 2, 3, 4, 1, -4, 3, 0, 9, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4]
        set_adapters!(
            exe,
            [
                HistoricIterable(
                    exe, values, [(DateTime(2000, 1, i), x) for (i, x) in enumerate(vals)]
                ),
            ],
        )
        run!(exe, DateTime(2000, 1, 1), DateTime(2000, 1, length(vals)))

        @test output.operation.buffer[end] ≈ StreamOps._ModifiedSincOrig.smoothMS(
            vals[(end - window_size + 1):end], deg, window_size
        )[end]
    end
end

@testitem "order=4" begin
    using Dates

    deg = 4

    for window_size in 2:2:10
        g = StreamGraph()
        values = source!(g, :values; out=Float64, init=0.0)
        avg = op!(g, :avg, ModifiedSinc{Float64,Float64}(window_size, deg); out=Float64)
        output = sink!(g, :output, Buffer{Float64}())
        bind!(g, values, avg)
        bind!(g, avg, output)

        states = compile_graph!(DateTime, g)
        exe = HistoricExecutor{DateTime}(g, states)
        setup!(exe)

        vals = Float64[1, 2, 3, 4, 1, -4, 3, 0, 9, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4]
        set_adapters!(
            exe,
            [
                HistoricIterable(
                    exe, values, [(DateTime(2000, 1, i), x) for (i, x) in enumerate(vals)]
                ),
            ],
        )
        run!(exe, DateTime(2000, 1, 1), DateTime(2000, 1, length(vals)))

        @test output.operation.buffer[end] ≈ StreamOps._ModifiedSincOrig.smoothMS(
            vals[(end - window_size + 1):end], deg, window_size
        )[end]
    end
end

@testitem "reset! clears state" begin
    using Test

    op = ModifiedSinc{Float64,Float64}(4, 2)

    for value in (1.0, 2.0, 3.0)
        op(nothing, value)
    end

    @test !isempty(op.buffer)
    @test op.filtered != 0.0

    reset!(op)

    @test isempty(op.buffer)
    @test op.filtered === 0.0

    op(nothing, 5.0)

    @test length(op.buffer) == 1
    @test op.filtered == 5.0
end
