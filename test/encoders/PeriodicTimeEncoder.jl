@testitem "PeriodicTimeEncoder" begin
    using Dates

    # Test with 1-day period
    encoder = PeriodicTimeEncoder(Day(1))

    # Start at epoch - should give (sin(0), cos(0)) = (0.0, 1.0)
    encoder(nothing, DateTime(1970, 1, 1))
    sin_val, cos_val = get_state(encoder)
    @test isapprox(sin_val, 0.0, atol=1e-10)
    @test isapprox(cos_val, 1.0, atol=1e-10)

    # Quarter day - should give (sin(π/2), cos(π/2)) = (1.0, 0.0)
    encoder(nothing, DateTime(1970, 1, 1, 6))
    sin_val, cos_val = get_state(encoder)
    @test isapprox(sin_val, 1.0, atol=1e-10)
    @test isapprox(cos_val, 0.0, atol=1e-10)

    # Half day - should give (sin(π), cos(π)) = (0.0, -1.0)
    encoder(nothing, DateTime(1970, 1, 1, 12))
    sin_val, cos_val = get_state(encoder)
    @test isapprox(sin_val, 0.0, atol=1e-10)
    @test isapprox(cos_val, -1.0, atol=1e-10)

    # Three quarters day - should give (sin(3π/2), cos(3π/2)) = (-1.0, 0.0)
    encoder(nothing, DateTime(1970, 1, 1, 18))
    sin_val, cos_val = get_state(encoder)
    @test isapprox(sin_val, -1.0, atol=1e-10)
    @test isapprox(cos_val, 0.0, atol=1e-10)

    # Full day - should be back to (sin(2π), cos(2π)) = (0.0, 1.0)
    encoder(nothing, DateTime(1970, 1, 2))
    sin_val, cos_val = get_state(encoder)
    @test isapprox(sin_val, 0.0, atol=1e-10)
    @test isapprox(cos_val, 1.0, atol=1e-10)

    # Test with 1-hour period
    encoder_hour = PeriodicTimeEncoder(Hour(1))

    # Start of hour - should give (0.0, 1.0)
    encoder_hour(nothing, DateTime(1970, 1, 1))
    sin_val, cos_val = get_state(encoder_hour)
    @test isapprox(sin_val, 0.0, atol=1e-10)
    @test isapprox(cos_val, 1.0, atol=1e-10)

    # 15 minutes - should give (1.0, 0.0)
    encoder_hour(nothing, DateTime(1970, 1, 1, 0, 15))
    sin_val, cos_val = get_state(encoder_hour)
    @test isapprox(sin_val, 1.0, atol=1e-10)
    @test isapprox(cos_val, 0.0, atol=1e-10)

    # Test is_valid
    @test is_valid(encoder)

    # Test new encoder is not valid
    @test !is_valid(PeriodicTimeEncoder(Day(1)))
end
