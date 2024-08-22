using Test
using Dates
using StreamOps

@testset verbose = true "Sample test w/o initial key" begin
    data = [
        (DateTime("2020-01-01T12:00:00"), 0.0), #  [1]  12:00:00 <- sampled
        (DateTime("2020-01-01T12:01:00"), 0.1), #  [2]  12:05:00 <- sampled
        (DateTime("2020-01-01T12:03:00"), 0.3), #  [3]  12:05:00
        (DateTime("2020-01-01T12:05:00"), 0.5), #  [4]  12:05:00
        (DateTime("2020-01-01T12:11:00"), 1.1), #  [5]  12:15:00 <- sampled
        (DateTime("2020-01-01T12:12:00"), 1.2), #  [6]  12:15:00
        (DateTime("2020-01-01T12:16:00"), 1.6), #  [7]  12:20:00 <- sampled
        (DateTime("2020-01-01T12:21:00"), 2.1), #  [8]  12:25:00 <- sampled
        (DateTime("2020-01-01T12:41:00"), 4.1), #  [9]  12:45:00 <- sampled
        (DateTime("2020-01-01T12:42:00"), 4.2), # [10]  12:45:00
    ]

    op = PeriodicSample{DateTime}(;
        date_fn=v -> v[1],
        period=Dates.Minute(5),
    )

    res = op.(data)
    # display(res)

    @test res[1] == (DateTime("2020-01-01T12:00:00"), 0.0)
    @test res[2] == (DateTime("2020-01-01T12:01:00"), 0.1)
    @test isnothing(res[3])
    @test isnothing(res[4])
    @test res[5] == (DateTime("2020-01-01T12:11:00"), 1.1)
    @test isnothing(res[6])
    @test res[7] == (DateTime("2020-01-01T12:16:00"), 1.6)
    @test res[8] == (DateTime("2020-01-01T12:21:00"), 2.1)
    @test res[9] == (DateTime("2020-01-01T12:41:00"), 4.1)
    @test isnothing(res[10])
end

@testset verbose = true "Sample test w/ initial_key equal first data point" begin
    data = [
        (DateTime("2020-01-01T12:00:00"), 0.0), #  [1]  12:00:00 <- sampled
        (DateTime("2020-01-01T12:01:00"), 0.1), #  [2]  12:05:00 <- sampled
        (DateTime("2020-01-01T12:03:00"), 0.3), #  [3]  12:05:00
        (DateTime("2020-01-01T12:05:00"), 0.5), #  [4]  12:05:00
        (DateTime("2020-01-01T12:11:00"), 1.1), #  [5]  12:15:00 <- sampled
        (DateTime("2020-01-01T12:12:00"), 1.2), #  [6]  12:15:00
        (DateTime("2020-01-01T12:16:00"), 1.6), #  [7]  12:20:00 <- sampled
        (DateTime("2020-01-01T12:21:00"), 2.1), #  [8]  12:25:00 <- sampled
        (DateTime("2020-01-01T12:41:00"), 4.1), #  [9]  12:45:00 <- sampled
        (DateTime("2020-01-01T12:42:00"), 4.2), # [10]  12:45:00
    ]

    op = PeriodicSample{DateTime}(;
        date_fn=v -> v[1],
        period=Dates.Minute(5),
        initial_date=data[1][1]
    )

    res = op.(data)
    # display(res)

    @test isnothing(res[1])
    @test res[2] == (DateTime("2020-01-01T12:01:00"), 0.1)
    @test isnothing(res[3])
    @test isnothing(res[4])
    @test res[5] == (DateTime("2020-01-01T12:11:00"), 1.1)
    @test isnothing(res[6])
    @test res[7] == (DateTime("2020-01-01T12:16:00"), 1.6)
    @test res[8] == (DateTime("2020-01-01T12:21:00"), 2.1)
    @test res[9] == (DateTime("2020-01-01T12:41:00"), 4.1)
    @test isnothing(res[10])
end
