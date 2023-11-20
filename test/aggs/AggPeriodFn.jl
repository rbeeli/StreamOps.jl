using Test
using Dates
using StreamOps


@testset verbose = true "AggPeriodFn" begin

    @testset "AggPeriodFn aggregation test" begin
        data = [
            (DateTime("2020-01-01T12:00:00"), 1.1),
            (DateTime("2020-01-01T12:01:00"), 1.0),
            (DateTime("2020-01-01T12:03:00"), 1.3),
            (DateTime("2020-01-01T12:06:00"), 1.6),
            (DateTime("2020-01-01T12:11:00"), 1.2),
            (DateTime("2020-01-01T12:15:00"), 1.5),
        ]

        agg = AggPeriodFn{eltype(data),DateTime}(;
            date_fn=value -> value[1],
            period_fn=date -> round_origin(date, Dates.Minute(5)),
            agg_fn=(period, buffer) -> begin
                (period, last(map(x -> x[2], buffer)))
            end,
            next=OpReturn()
        )

        # display(agg.(data))
        @test agg(data[1]) == (DateTime("2020-01-01T12:00:00"), 1.1)
        @test isnothing(agg(data[2]))
        @test isnothing(agg(data[3]))
        @test agg(data[4]) == (DateTime("2020-01-01T12:05:00"), 1.3)
        @test agg(data[5]) == (DateTime("2020-01-01T12:10:00"), 1.6)
        @test agg(data[6]) == (DateTime("2020-01-01T12:15:00"), 1.5)
    end

    @testset "AggPeriodFn not sorted error test" begin
        data = [
            (DateTime("2020-01-01T12:00:00"), 1.1),
            (DateTime("2020-01-01T12:03:00"), 1.3),
            (DateTime("2020-01-01T12:01:00"), 1.0),
        ]

        agg = AggPeriodFn{eltype(data),DateTime}(;
            date_fn=value -> value[1],
            period_fn=date -> round_origin(date, Dates.Minute(5)),
            agg_fn=(period, buffer) -> begin
                (period, last(map(x -> x[2], buffer)))
            end,
            next=OpReturn()
        )

        @test_throws ArgumentError agg.(data)
    end

    @testset "AggPeriodFn not unique test" begin
        data = [
            (DateTime("2020-01-01T12:00:00"), 1.1),
            (DateTime("2020-01-01T12:03:00"), 1.3),
            (DateTime("2020-01-01T12:03:00"), 1.3),
        ]

        agg = AggPeriodFn{eltype(data),DateTime}(;
            date_fn=value -> value[1],
            period_fn=date -> round_origin(date, Dates.Minute(5)),
            agg_fn=(period, buffer) -> begin
                (period, last(map(x -> x[2], buffer)))
            end,
            next=OpReturn()
        )

        @test_throws ArgumentError agg.(data)
    end

    @testset "round_origin Tests" begin
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

end