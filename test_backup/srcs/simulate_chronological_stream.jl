using Test
using StreamOps, Dates

@testset "simulate chronological" begin
    output = []

    periodic_source = PeriodicDateSource(
        DateTime(2018, 1, 1),
        DateTime(2018, 1, 6),
        Day(1))

    dates_source = IterableSource([
        DateTime(2017, 1, 1),
        DateTime(2017, 1, 5),
        DateTime(2017, 1, 7),
        DateTime(2017, 1, 10)
    ])

    dates_source2 = IterableSource([
        DateTime(2017, 1, 1),
        DateTime(2017, 1, 3),
        DateTime(2017, 1, 7),
        DateTime(2017, 1, 31)
    ])

    pipe1 = @streamops begin
        Collect(output)
    end

    pipe2 = @streamops begin
        Collect(output)
    end

    pipe3 = @streamops begin
        Collect(output)
    end

    simulate_chronological_stream(
        DateTime,
        DateTime,
        (periodic_source, dates_source, dates_source2),
        (x -> x, x -> x, x -> x),
        (pipe1, pipe2, pipe3)
    )

    # display(output)

    # ensure dates are in chronological order
    for i in 1:length(output)-1
        @test output[i] <= output[i+1]
    end

    # 2017-01-01 should occur twice in output
    @test sum(output .== DateTime(2017, 1, 1)) == 2

    # 2017-01-07 should occur twice in output
    @test sum(output .== DateTime(2017, 1, 7)) == 2
end
