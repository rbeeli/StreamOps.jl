@testitem "round_origin DateTime" begin
    using Dates

    # basic
    @test round_origin(DateTime("2019-01-01T12:30:00"), Hour(1), RoundUp) == DateTime("2019-01-01T13:00:00")
    @test round_origin(DateTime("2019-06-15T05:45:00"), Day(1), RoundUp) == DateTime("2019-06-16T00:00:00")
    @test round_origin(DateTime("2019-12-31T23:59:00"), Month(1), RoundUp) == DateTime("2020-01-01T00:00:00")

    # rounding
    @test round_origin(DateTime("2019-01-01T12:30:00"), Hour(1), RoundDown) == DateTime("2019-01-01T12:00:00")
    @test round_origin(DateTime("2019-01-01T12:30:00"), Hour(1), RoundUp) == DateTime("2019-01-01T13:00:00")
    @test round_origin(DateTime("2019-01-01T12:30:00"), Hour(1), RoundNearestTiesUp) == DateTime("2019-01-01T13:00:00")

    # edge Cases
    @test round_origin(DateTime("2019-01-01T00:00:00"), Day(1), RoundUp) == DateTime("2019-01-01T00:00:00")
    @test round_origin(DateTime("2019-01-01T23:59:00"), Day(1), RoundUp) == DateTime("2019-01-02T00:00:00")
    @test round_origin(DateTime("2019-01-01T12:30:00"), Minute(30), RoundDown) == DateTime("2019-01-01T12:30:00")
    @test round_origin(DateTime("2019-01-01T12:30:00"), Minute(30), RoundUp) == DateTime("2019-01-01T12:30:00")

    # non-default origin
    origin = DateTime("2018-12-31T12:30:00")
    @test round_origin(DateTime("2019-01-01T12:29:00"), Hour(1), RoundDown, origin=origin) == DateTime("2019-01-01T11:30:00")
    @test round_origin(DateTime("2019-01-01T12:22:00"), Hour(1), RoundUp, origin=origin) == DateTime("2019-01-01T12:30:00")
end

@testitem "round_origin Float64" begin
    @test round_origin(1.5, 1.0, RoundDown) == 1.0
    @test round_origin(1.5, 1.0, RoundUp) == 2.0
    @test round_origin(1.5, 1.0, RoundNearestTiesUp) == 2.0
    @test round_origin(1.0, 1.0, RoundDown, origin=0.5) == 0.5
end

@testitem "nanos_since_epoch_zero" begin
    using Dates

    # Test epoch start (1970-01-01)
    @test nanos_since_epoch_zero(DateTime(1970, 1, 1)) == 0

    # Test one second after epoch
    @test nanos_since_epoch_zero(DateTime(1970, 1, 1, 0, 0, 1)) == 1_000_000_000

    # Test one day after epoch
    @test nanos_since_epoch_zero(DateTime(1970, 1, 2)) == 86_400_000_000_000

    # Test one year after epoch
    @test nanos_since_epoch_zero(DateTime(1971, 1, 1)) == 365 * 86_400_000_000_000

    # Test before epoch (should handle negative values)
    @test nanos_since_epoch_zero(DateTime(1969, 12, 31, 23, 59, 59)) == -1_000_000_000

    # Test with millisecond precision
    @test nanos_since_epoch_zero(DateTime(1970, 1, 1, 0, 0, 0, 1)) == 1_000_000

    # Test current time roughly matches expected range
    current_nanos = nanos_since_epoch_zero(now())
    @test current_nanos > 1_500_000_000_000_000_000  # Ensure it's at least year 2017
    @test current_nanos < 2_000_000_000_000_000_000  # Ensure it's before year 2033
end
