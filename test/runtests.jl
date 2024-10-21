using Test
using StreamOps
using Dates

# To run a subset of tests, call Pkg.test as follows:
#
# import Pkg;Pkg.test("StreamOps", test_args=["bind.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["call_policies.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["adapters/HistoricIterable.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["executors/RealtimeExecutor.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["operations/Buffer.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["operations/RingBuffer.jl"])
# import Pkg;Pkg.test("StreamOps", test_args=["statistics/Skewness.jl"])

requested_tests = ARGS

if isempty(requested_tests)
    include("utils.jl")

    include("graph.jl")
    include("bind.jl")
    include("call_policies.jl")

    include("operations/Func.jl")
    include("operations/Constant.jl")
    include("operations/Print.jl")
    include("operations/Buffer.jl")
    include("operations/RingBuffer.jl")
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
    include("statistics/SavitzkyGolay.jl")

    include("adapters/HistoricIterable.jl")

    include("executors/HistoricExecutor.jl")
    include("executors/RealtimeExecutor.jl")
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
