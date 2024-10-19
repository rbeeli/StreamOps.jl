using Test
using StreamOps

@testset verbose = true "FractionalDiff" begin

    @testset "order=0.99" begin
        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        frac_diff = op!(g, :frac_diff, FractionalDiff{Float64,Float64}(0.99), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, frac_diff)
        bind!(g, frac_diff, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, #
            -3.0, 150.0, -400.0, 50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0, #
            50.0, 1.5, 1.1, 4.0, -3.0, 150.0, -400.0]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        adapters = [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)

        # Reference values generated using Python script ./FractionalDiff.py
        expected = [3.0735819920702734, -6.859030168988753, 153.02035742475738,
            -548.4410855286475, 445.29766956916126, -46.23978225929855,
            -0.053730985383909635, 3.0735819920702734, -6.859030168988753,
            153.02035742475738, -548.4410855286475, 445.29766956916126,
            -46.23978225929855, -0.053730985383909635, 3.0735819920702734,
            -6.859030168988753, 153.02035742475738, -548.4410855286475]
        @test output.operation.buffer ≈ expected atol = 1e-5
    end

    @testset "order=1 (First Difference)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        frac_diff = op!(g, :frac_diff, FractionalDiff{Float64,Float64}(1.0), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, frac_diff)
        bind!(g, frac_diff, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        adapters = [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 3.0),
                (DateTime(2000, 1, 3), 6.0),
                (DateTime(2000, 1, 4), 10.0),
                (DateTime(2000, 1, 5), 15.0)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)

        # For order 1, we expect first differences
        expected = [2.0, 3.0, 4.0, 5.0]
        @test output.operation.buffer ≈ expected
    end

    @testset "order=0 (Identity)" begin
        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        frac_diff = op!(g, :frac_diff, FractionalDiff{Float64,Float64}(0.0), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, frac_diff)
        bind!(g, frac_diff, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, 5)
        adapters = [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, 1), 1.0),
                (DateTime(2000, 1, 2), 2.0),
                (DateTime(2000, 1, 3), 3.0),
                (DateTime(2000, 1, 4), 4.0),
                (DateTime(2000, 1, 5), 5.0)
            ])
        ]
        run_simulation!(exe, adapters, start, stop)

        # For order 0, we expect the original values
        expected = [1.0, 2.0, 3.0, 4.0, 5.0]
        @test output.operation.buffer ≈ expected
    end

end
