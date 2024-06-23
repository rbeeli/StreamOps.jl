using Test
using StreamOps

# To run a subset of tests, call Pkg.test as follows:
#
#   Pkg.test("StreamOps", test_args=["stats/OpStd.jl"])
#   Pkg.test("StreamOps", test_args=["ops/Combine.jl"])
#   Pkg.test("StreamOps", test_args=["ops/Sample.jl"])
#   Pkg.test("StreamOps", test_args=["pipelines/pipelines.jl"])
#   Pkg.test("StreamOps", test_args=["pipelines/broadcast.jl"])
#   Pkg.test("StreamOps", test_args=["pipelines/filter.jl"])
#   Pkg.test("StreamOps", test_args=["srcs/simulate_chronological_stream.jl"])

requested_tests = ARGS

if isempty(requested_tests)
    include("utils.jl")

    include("ops/Accumulate.jl")
    include("ops/Apply.jl")
    include("ops/Aggregate.jl")
    include("ops/Sample.jl")
    include("ops/Collect.jl")
    include("ops/Combine.jl")
    include("ops/CombineTuple.jl")
    include("ops/ForwardFill.jl")
    include("ops/FracChange.jl")
    include("ops/Transform.jl")
    include("ops/Hook.jl")
    include("ops/Lag.jl")
    include("ops/Counter.jl")
    include("ops/Prev.jl")
    include("ops/Print.jl")
    include("ops/RollingWindow.jl")

    include("stats/EWMean.jl")
    include("stats/EWStd.jl")
    include("stats/EWZScore.jl")
    include("stats/RollingMean.jl")
    include("stats/RollingSkew.jl")
    include("stats/RollingStd.jl")
    include("stats/RollingZScore.jl")

    include("pipelines/pipelines.jl")
    include("pipelines/filter.jl")
    include("pipelines/skipIf.jl")
    include("pipelines/broadcast.jl")
    include("pipelines/broadcast_collect.jl")

    include("srcs/simulate_chronological_stream.jl")
else
    println('-'^60)
    println("Running subset of tests:")
    for test in requested_tests
        println("  $test")
    end
    println('-'^60)

    for test in requested_tests
        include(test)
    end
end
