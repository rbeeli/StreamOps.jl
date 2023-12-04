using Test
using StreamOps, Dates


@testset "simulate chronological" begin

    output = []

    periodic_source = PeriodicSource(;
        next=(@streamops begin
            Timestamper{DateTime,DateTime}(; date_fn=identity)
            Collect(output)
        end),
        start_date=DateTime(2018, 1, 1),
        end_date=DateTime(2018, 1, 6),
        period=Day(1))

    dates_source = IterableSource(;
        next=(@streamops begin
            Timestamper{DateTime,DateTime}(; date_fn=identity)
            Collect(output)
        end),
        data=[
            DateTime(2017, 1, 1),
            DateTime(2017, 1, 5),
            DateTime(2017, 1, 7),
            DateTime(2017, 1, 10)
        ])

    dates_source2 = IterableSource(;
        next=(@streamops begin
            Timestamper{DateTime,DateTime}(; date_fn=identity)
            Collect(output)
        end),
        data=[
            DateTime(2017, 1, 1),
            DateTime(2017, 1, 3),
            DateTime(2017, 1, 7),
            DateTime(2017, 1, 31)
        ])

    simulate_chronological_stream(
        DateTime,
        (periodic_source, dates_source, dates_source2)
    )

    # display(output)

    # ensure that the dates are in chronological order
    for i in 1:length(output)-1
        @test output[i] <= output[i+1]
    end

    # 2017-01-01 should occur twice in output
    @test sum(output .== DateTime(2017, 1, 1)) == 2

    # 2017-01-07 should occur twice in output
    @test sum(output .== DateTime(2017, 1, 7)) == 2

end
