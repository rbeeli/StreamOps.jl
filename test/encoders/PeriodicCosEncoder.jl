@testitem "PeriodicCosEncoder" begin
    using Dates

    # Test with 1-day period
    encoder = PeriodicCosEncoder(Day(1))

    # Start at epoch - should give cos(0) = 1.0
    encoder(nothing, DateTime(1970, 1, 1))
    @test isapprox(get_state(encoder), 1.0, atol=1e-10)

    # Quarter day - should give cos(π/2) = 0.0
    encoder(nothing, DateTime(1970, 1, 1, 6))
    @test isapprox(get_state(encoder), 0.0, atol=1e-10)

    # Half day - should give cos(π) = -1.0
    encoder(nothing, DateTime(1970, 1, 1, 12))
    @test isapprox(get_state(encoder), -1.0, atol=1e-10)

    # Three quarters day - should give cos(3π/2) = 0.0
    encoder(nothing, DateTime(1970, 1, 1, 18))
    @test isapprox(get_state(encoder), 0.0, atol=1e-10)

    # Full day - should be back to cos(2π) = 1.0
    encoder(nothing, DateTime(1970, 1, 2))
    @test isapprox(get_state(encoder), 1.0, atol=1e-10)

    # Test with 1-hour period
    encoder_hour = PeriodicCosEncoder(Hour(1))

    # Start of hour
    encoder_hour(nothing, DateTime(1970, 1, 1))
    @test isapprox(get_state(encoder_hour), 1.0, atol=1e-10)

    # 15 minutes - should give cos(π/2)
    encoder_hour(nothing, DateTime(1970, 1, 1, 0, 15))
    @test isapprox(get_state(encoder_hour), 0.0, atol=1e-10)

    # Test is_valid
    @test is_valid(encoder)

    # Test new encoder is not valid
    @test !is_valid(PeriodicCosEncoder(Day(1)))
end

@testitem "PeriodicCosEncoder pipeline" begin
    using Dates

    g = StreamGraph()

    timestamps = source!(g, :timestamps, out=DateTime, init=DateTime(0))
    cos_encoder = op!(g, :cos_encoder, PeriodicCosEncoder(Hour(24)), out=Float64)
    output = sink!(g, :output, Buffer{Float64}())

    bind!(g, timestamps, cos_encoder)
    bind!(g, cos_encoder, output)

    states = compile_graph!(DateTime, g)
    exe = HistoricExecutor{DateTime}(g, states)
    setup!(exe)

    # Testing over a 24-hour period
    start = DateTime(2000, 1, 1)
    stop = DateTime(2000, 1, 2)

    # Create test timestamps at 6-hour intervals
    set_adapters!(exe, [
        HistoricIterable(exe, timestamps, [
            (DateTime(2000, 1, 1, 0, 0), DateTime(2000, 1, 1, 0, 0)),  # 0 hours - should give cos(0) = 1
            (DateTime(2000, 1, 1, 6, 0), DateTime(2000, 1, 1, 6, 0)),  # 6 hours - should give cos(π/2) = 0
            (DateTime(2000, 1, 1, 12, 0), DateTime(2000, 1, 1, 12, 0)), # 12 hours - should give cos(π) = -1
            (DateTime(2000, 1, 1, 18, 0), DateTime(2000, 1, 1, 18, 0)), # 18 hours - should give cos(3π/2) = 0
        ])
    ])
    run!(exe, start, stop)

    # Test with tolerance due to floating-point arithmetic
    @test isapprox(output.operation.buffer[1], 1.0, atol=1e-10)
    @test isapprox(output.operation.buffer[2], 0.0, atol=1e-10)
    @test isapprox(output.operation.buffer[3], -1.0, atol=1e-10)
    @test isapprox(output.operation.buffer[4], 0.0, atol=1e-10)
end
