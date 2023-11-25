using Test
using Dates
using StreamOps


@testset verbose = true "AggPeriodFn" begin

    @testset "AggPeriodFn aggregation test" begin
        data = [
            (DateTime("2020-01-01T12:00:00"), 0.0),
            (DateTime("2020-01-01T12:01:00"), 0.1),
            (DateTime("2020-01-01T12:03:00"), 0.3),

            (DateTime("2020-01-01T12:05:00"), 0.5), # exactly on period end, will not flush buffer
            (DateTime("2020-01-01T12:11:00"), 1.1),
            (DateTime("2020-01-01T12:12:00"), 1.2),

            (DateTime("2020-01-01T12:16:00"), 1.6),
            (DateTime("2020-01-01T12:21:00"), 2.1),
            (DateTime("2020-01-01T12:41:00"), 4.1),

            (DateTime("2020-01-01T12:42:00"), 4.2),
        ]

        agg = AggPeriodFn{eltype(data),DateTime}(;
            date_fn=value -> value[1],
            # subtract 1 ns so that if df = period_df, then the
            # record will be included in the current, not next period
            period_fn=date -> round_origin(date, Dates.Minute(5)), #  - Dates.Nanosecond(1)
            agg_fn=(period, buffer) -> begin
                isempty(buffer) && return nothing
                (period, last(map(x -> x[2], buffer)))
            end,
            next=OpReturn()
        )

        res = agg.(data)
        display(res)

        @test isnothing(res[1])
        @test res[2] == (DateTime("2020-01-01T12:00:00"), 0.0)
        @test isnothing(res[3])

        @test isnothing(res[4])
        @test res[5] == (DateTime("2020-01-01T12:05:00"), 0.5)
        @test isnothing(res[6])
        
        @test res[7] == (DateTime("2020-01-01T12:15:00"), 1.2)
        @test res[8] == (DateTime("2020-01-01T12:20:00"), 1.6)
        @test res[9] == (DateTime("2020-01-01T12:25:00"), 2.1)
        @test isnothing(res[10])

        @test agg.current_period == DateTime("2020-01-01T12:45:00")
    end

    # @testset "AggPeriodFn not sorted error test" begin
    #     data = [
    #         (DateTime("2020-01-01T12:00:00"), 1.1),
    #         (DateTime("2020-01-01T12:03:00"), 1.3),
    #         (DateTime("2020-01-01T12:01:00"), 1.0),
    #     ]

    #     agg = AggPeriodFn{eltype(data),DateTime}(;
    #         date_fn=value -> value[1],
    #         period_fn=date -> round_origin(date, Dates.Minute(5)),
    #         agg_fn=(period, buffer) -> begin
    #             (period, last(map(x -> x[2], buffer)))
    #         end,
    #         next=OpReturn()
    #     )

    #     @test_throws ArgumentError agg.(data)
    # end

    # @testset "AggPeriodFn not unique test" begin
    #     data = [
    #         (DateTime("2020-01-01T12:00:00"), 1.1),
    #         (DateTime("2020-01-01T12:03:00"), 1.3),
    #         (DateTime("2020-01-01T12:03:00"), 1.3),
    #     ]

    #     agg = AggPeriodFn{eltype(data),DateTime}(;
    #         date_fn=value -> value[1],
    #         period_fn=date -> round_origin(date, Dates.Minute(5)),
    #         agg_fn=(period, buffer) -> begin
    #             (period, last(map(x -> x[2], buffer)))
    #         end,
    #         next=OpReturn()
    #     )

    #     @test_throws ArgumentError agg.(data)
    # end

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