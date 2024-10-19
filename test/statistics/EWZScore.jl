using Test
using StreamOps
using Statistics

@testset verbose = true "EWZScore" begin

    @testset "corrected=true(default)" begin
        alpha = 0.1

        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        ewzscore = op!(g, :ewzscore, EWZScore{Float64,Float64}(alpha=alpha), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, ewzscore)
        bind!(g, ewzscore, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])
        run!(exe, start, stop)

        # Reference values generated by pandas, see ./EWZScore.py
        expected = [NaN, 0.669890634808308, 0.9307483192137187, 1.0627451970929696, -0.9205872524292463, -0.1567274634253095, 0.6035746947545808, 1.1458108636671736, -1.0828267387011528, -0.26599304936641255]

        for i in 1:length(vals)
            if isnan(output.operation.buffer[i])
                @test isnan(expected[i])
            else
                @test isapprox(output.operation.buffer[i], expected[i], atol=1e-6)
            end
        end
    end

    @testset "corrected=false" begin
        alpha = 0.2

        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        ewzscore = op!(g, :ewzscore, EWZScore{Float64,Float64}(alpha=alpha, corrected=false), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, ewzscore)
        bind!(g, ewzscore, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)

        vals = [1.0, 2.0, 3.0, 4.0, 1.0, 2.0, 3.0, 4.0, 1.0, 2.0]
        start = DateTime(2000, 1, 1)
        stop = DateTime(2000, 1, length(vals))
        set_adapters!(exe, [
            HistoricIterable(exe, values, [
                (DateTime(2000, 1, i), x)
                for (i, x) in enumerate(vals)
            ])
        ])
        run!(exe, start, stop)

        # Reference values generated by pandas, see ./EWZScore.py
        expected = [NaN, 1.9999999999999996, 1.7910669423779804, 1.610148965142507, -0.7211831713599367, 0.12409180469633556, 0.8724207021626663, 1.2700287304741265, -0.9651967296715184, -0.13251735878064783]

        for i in 1:length(vals)
            if isnan(output.operation.buffer[i])
                @test isnan(expected[i])
            else
                @test isapprox(output.operation.buffer[i], expected[i], atol=1e-6)
            end
        end
    end

    @testset "Edge case: Single value" begin
        alpha = 0.1

        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        ewzscore = op!(g, :ewzscore, EWZScore{Float64,Float64}(alpha=alpha), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, ewzscore)
        bind!(g, ewzscore, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)
        set_adapters!(exe, [
            HistoricIterable(exe, values, [(DateTime(2000, 1, 1), 1.0)])
        ])
        run!(exe, DateTime(2000, 1, 1), DateTime(2000, 1, 1))

        @test isnan(output.operation.buffer[1])
        @test length(output.operation.buffer) == 1
    end

    @testset "Edge case: Constant values" begin
        alpha = 0.1

        g = StreamGraph()

        values = source!(g, :values, out=Float64, init=0.0)
        ewzscore = op!(g, :ewzscore, EWZScore{Float64,Float64}(alpha=alpha), out=Float64)
        output = sink!(g, :output, Buffer{Float64}())

        bind!(g, values, ewzscore)
        bind!(g, ewzscore, output)

        exe = compile_historic_executor(DateTime, g; debug=!true)
        constant_vals = [2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
        set_adapters!(exe, [
            HistoricIterable(exe, values, [(DateTime(2000, 1, i), x) for (i, x) in enumerate(constant_vals)])
        ])
        run!(exe, DateTime(2000, 1, 1), DateTime(2000, 1, length(constant_vals)))

        @test all(isnan.(output.operation.buffer))
    end

end
