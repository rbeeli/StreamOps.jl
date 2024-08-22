using Test
using Dates
using StreamOps

@testset verbose = true "round_origin Tests" begin
    # basic
    @test round_origin(DateTime("2019-01-01T12:30:00"), Hour(1)) == DateTime("2019-01-01T13:00:00")
    @test round_origin(DateTime("2019-06-15T05:45:00"), Day(1)) == DateTime("2019-06-16T00:00:00")
    @test round_origin(DateTime("2019-12-31T23:59:00"), Month(1)) == DateTime("2020-01-01T00:00:00")

    # rounding
    @test round_origin(DateTime("2019-01-01T12:30:00"), Hour(1); mode=RoundDown) == DateTime("2019-01-01T12:00:00")
    @test round_origin(DateTime("2019-01-01T12:30:00"), Hour(1); mode=RoundUp) == DateTime("2019-01-01T13:00:00")
    @test round_origin(DateTime("2019-01-01T12:30:00"), Hour(1); mode=RoundNearestTiesUp) == DateTime("2019-01-01T13:00:00")

    # edge Cases
    @test round_origin(DateTime("2019-01-01T00:00:00"), Day(1)) == DateTime("2019-01-01T00:00:00")
    @test round_origin(DateTime("2019-01-01T23:59:00"), Day(1)) == DateTime("2019-01-02T00:00:00")
    @test round_origin(DateTime("2019-01-01T12:30:00"), Minute(30); mode=RoundDown) == DateTime("2019-01-01T12:30:00")
    @test round_origin(DateTime("2019-01-01T12:30:00"), Minute(30); mode=RoundUp) == DateTime("2019-01-01T12:30:00")

    # non-default origin
    origin = DateTime("2018-12-31T12:30:00")
    @test round_origin(DateTime("2019-01-01T12:29:00"), Hour(1); mode=RoundDown, origin) == DateTime("2019-01-01T11:30:00")
    @test round_origin(DateTime("2019-01-01T12:22:00"), Hour(1); mode=RoundUp, origin) == DateTime("2019-01-01T12:30:00")
end
