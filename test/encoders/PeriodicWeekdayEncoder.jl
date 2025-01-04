@testitem "PeriodicWeekdayEncoder" begin
    using Dates

    # Test with default start (Monday)
    encoder_mon = PeriodicWeekdayEncoder()

    # Monday (maps to 0 when Monday start)
    encoder_mon(nothing, DateTime(1970, 1, 5))  # Jan 5, 1970 was a Monday
    sin_val, cos_val = get_state(encoder_mon)
    @test isapprox(sin_val, 0.0, atol=1e-10)  # sin(0)
    @test isapprox(cos_val, 1.0, atol=1e-10)  # cos(0)

    # Sunday (maps to 6 when Monday start)
    encoder_mon(nothing, DateTime(1970, 1, 4))
    sin_val, cos_val = get_state(encoder_mon)
    @test isapprox(sin_val, sin(2π * 6/7), atol=1e-10)
    @test isapprox(cos_val, cos(2π * 6/7), atol=1e-10)

    # Test with Sunday start
    encoder_sun = PeriodicWeekdayEncoder(start_of_week=Dates.Sun)

    # Sunday (maps to 0 when Sunday start)
    encoder_sun(nothing, DateTime(1970, 1, 4))
    sin_val, cos_val = get_state(encoder_sun)
    @test isapprox(sin_val, 0.0, atol=1e-10)
    @test isapprox(cos_val, 1.0, atol=1e-10)

    # Monday (maps to 1 when Sunday start)
    encoder_sun(nothing, DateTime(1970, 1, 5))
    sin_val, cos_val = get_state(encoder_sun)
    @test isapprox(sin_val, sin(2π * 1/7), atol=1e-10)
    @test isapprox(cos_val, cos(2π * 1/7), atol=1e-10)

    # Test with Saturday start
    encoder_sat = PeriodicWeekdayEncoder(start_of_week=Dates.Sat)

    # Saturday (maps to 0 when Saturday start)
    encoder_sat(nothing, DateTime(1970, 1, 3))
    sin_val, cos_val = get_state(encoder_sat)
    @test isapprox(sin_val, 0.0, atol=1e-10)
    @test isapprox(cos_val, 1.0, atol=1e-10)

    # Test invalid start day
    @test_throws AssertionError PeriodicWeekdayEncoder(start_of_week=0)
    @test_throws AssertionError PeriodicWeekdayEncoder(start_of_week=8)

    # Test is_valid
    @test is_valid(encoder_mon)
    @test !is_valid(PeriodicWeekdayEncoder())
end
