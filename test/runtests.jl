using Test
using StreamOps


# To run a subset of tests, call Pkg.test as follows:
#
#   Pkg.test("StreamOps", test_args=["stats/OpStd.jl"])
#   Pkg.test("StreamOps", test_args=["ops/Combine.jl"])
#   Pkg.test("StreamOps", test_args=["pipelines/pipelines.jl"])
#   Pkg.test("StreamOps", test_args=["pipelines/broadcast.jl"])
#   Pkg.test("StreamOps", test_args=["pipelines/filter.jl"])
#   Pkg.test("StreamOps", test_args=["srcs/simulate_chronological_stream.jl"])


requested_tests = ARGS

if isempty(requested_tests)
    include("ops/Aggregate.jl")
    include("ops/Collect.jl")
    include("ops/Combine.jl")
    include("ops/ForwardFill.jl")
    include("ops/FracChange.jl")
    include("ops/Func.jl")
    include("ops/Hook.jl")
    include("ops/Lag.jl")
    include("ops/Prev.jl")
    include("ops/Print.jl")
    include("ops/SlidingWindow.jl")

    include("stats/EWMean.jl")
    include("stats/EWStd.jl")
    include("stats/EWZScore.jl")
    include("stats/Mean.jl")
    include("stats/Skew.jl")
    include("stats/Std.jl")
    include("stats/ZScore.jl")

    include("pipelines/pipelines.jl")
    include("pipelines/filter.jl")
    include("pipelines/broadcast.jl")
    include("pipelines/collect_tuple.jl")
else
    println('-' ^ 60)
    println("Running subset of tests:")
    for test in requested_tests
        println("  $test")
    end
    println('-' ^ 60)

    for test in requested_tests
        include(test)
    end
end
