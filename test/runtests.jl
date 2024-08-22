using Test
using StreamOps

# To run a subset of tests, call Pkg.test as follows:
#
#   import Pkg;Pkg.test("StreamOps", test_args=["ops/Combine.jl"])
#   import Pkg;Pkg.test("StreamOps", test_args=["ops/Sample.jl"])
#   import Pkg;Pkg.test("StreamOps", test_args=["ops/PeriodicSample.jl"])
#   import Pkg;Pkg.test("StreamOps", test_args=["pipelines/pipelines.jl"])
#   import Pkg;Pkg.test("StreamOps", test_args=["pipelines/broadcast.jl"])
#   import Pkg;Pkg.test("StreamOps", test_args=["pipelines/filter.jl"])
#   import Pkg;Pkg.test("StreamOps", test_args=["stats/FracDiff.jl"])
#   import Pkg;Pkg.test("StreamOps", test_args=["srcs/simulate_chronological_stream.jl"])

requested_tests = ARGS

if isempty(requested_tests)
    include("utils.jl")

    include("multi_input.jl")

    # include("ops/Accumulate.jl")
    # include("ops/Apply.jl")
    # include("ops/Aggregate.jl")
    # include("ops/Sample.jl")
    # include("ops/PeriodicSample.jl")
    # include("ops/Collect.jl")
    # include("ops/Sink.jl")
    # include("ops/Combine.jl")
    # include("ops/CombineTuple.jl")
    # include("ops/ForwardFill.jl")
    # include("ops/Transform.jl")
    # include("ops/Hook.jl")
    # include("ops/Lag.jl")
    # include("ops/Counter.jl")
    # include("ops/Prev.jl")
    # include("ops/Print.jl")

    # include("stats/PctChange.jl")
    # include("stats/FracDiff.jl")
    # include("stats/EWMean.jl")
    # include("stats/EWStd.jl")
    # include("stats/EWZScore.jl")
    # include("stats/RollingMean.jl")
    # include("stats/RollingSkew.jl")
    # include("stats/RollingStd.jl")
    # include("stats/RollingZScore.jl")
    
    include("operations/Buffer.jl")
    include("operations/WindowBuffer.jl")

    include("statistics/Counter.jl")
    include("statistics/Diff.jl")
    include("statistics/PctChange.jl")
    include("statistics/Mean.jl")
    include("statistics/Variance.jl")
    include("statistics/EWMean.jl")

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
