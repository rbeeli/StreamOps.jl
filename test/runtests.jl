using Test
using StreamOps
using Dates

# To run a subset of tests, call Pkg.test as follows:
#
# import Pkg;Pkg.test("StreamOps", test_args=["bind.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["call_policies.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["adapters/IterableAdapter.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["operations/TimeWindowBuffer.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["operations/TimeSampler.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["operations/WindowBuffer.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["operations/TimeTupleBuffer.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["operations/Func.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["operations/Print.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["statistics/Mean.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["statistics/EWZScore.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["statistics/FractionalDiff.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["statistics/Skewness.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["statistics/TimeMean.jl"])

requested_tests = ARGS

if isempty(requested_tests)
    include("utils.jl")

    include("graph.jl")
    include("bind.jl")
    include("call_policies.jl")

    include("operations/Func.jl")
    include("operations/Print.jl")
    include("operations/Buffer.jl")
    include("operations/TimeTupleBuffer.jl")
    include("operations/Lag.jl")
    include("operations/Copy.jl")
    include("operations/ForwardFill.jl")
    include("operations/WindowBuffer.jl")
    include("operations/TimeWindowBuffer.jl")
    include("operations/TimeSampler.jl")

    include("statistics/Counter.jl")
    include("statistics/Diff.jl")
    include("statistics/PctChange.jl")
    include("statistics/Mean.jl")
    include("statistics/Variance.jl")
    include("statistics/Skewness.jl")
    include("statistics/ZScore.jl")
    include("statistics/EWMean.jl")
    include("statistics/EWVariance.jl")
    include("statistics/EWZScore.jl")
    include("statistics/FractionalDiff.jl")
    include("statistics/TimeCount.jl")
    include("statistics/TimeSum.jl")
    include("statistics/TimeMean.jl")

    include("adapters/IterableAdapter.jl")
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
