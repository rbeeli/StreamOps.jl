using Test
using Dates
using StreamOps

@testset verbose = true "Aggregate test" begin
    data = [
        (DateTime("2020-01-01T12:00:00"), 0.0), #  [1]  12:00:00 <- aggregate (nothing)
        (DateTime("2020-01-01T12:01:00"), 0.1), #  [2]  12:05:00 <- aggregate
        (DateTime("2020-01-01T12:03:00"), 0.3), #  [3]  12:05:00
        (DateTime("2020-01-01T12:05:00"), 0.5), #  [4]  12:05:00
        (DateTime("2020-01-01T12:11:00"), 1.1), #  [5]  12:15:00 <- aggregate
        (DateTime("2020-01-01T12:12:00"), 1.2), #  [6]  12:15:00
        (DateTime("2020-01-01T12:16:00"), 1.6), #  [7]  12:20:00 <- aggregate
        (DateTime("2020-01-01T12:21:00"), 2.1), #  [8]  12:25:00 <- aggregate
        (DateTime("2020-01-01T12:41:00"), 4.1), #  [9]  12:45:00 <- aggregate
        (DateTime("2020-01-01T12:42:00"), 4.2), # [10]  12:45:00
    ]

    agg = Aggregate{eltype(data),DateTime}(;
        initial_key=DateTime(0),
        key_fn=v -> round_origin(v[1], Dates.Minute(5)),
        agg_fn=(key, buffer) -> begin
            isempty(buffer) && return nothing
            (key, last(buffer)[1], last(buffer)[2])
        end
    )

    res = agg.(data)
    # display(res)

    @test res[1] ===  nothing
    @test res[2] == (DateTime("2020-01-01T12:00:00"), DateTime("2020-01-01T12:00:00"), 0.0)
    @test res[3] === nothing
    @test res[4] === nothing
    @test res[5] == (DateTime("2020-01-01T12:05:00"), DateTime("2020-01-01T12:05:00"), 0.5)
    @test res[6] === nothing
    @test res[7] == (DateTime("2020-01-01T12:15:00"), DateTime("2020-01-01T12:12:00"), 1.2)
    @test res[8] == (DateTime("2020-01-01T12:20:00"), DateTime("2020-01-01T12:16:00"), 1.6)
    @test res[9] == (DateTime("2020-01-01T12:25:00"), DateTime("2020-01-01T12:21:00"), 2.1)
    @test res[10] === nothing
end
