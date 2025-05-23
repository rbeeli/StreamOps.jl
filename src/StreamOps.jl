module StreamOps

include("utils.jl")
include("types.jl")
include("errors.jl")

include("graph/call_policies.jl")
include("graph/params_bindings.jl")
include("graph/InputBinding.jl")
include("graph/StreamNode.jl")
include("graph/StreamGraph.jl")
include("graph/graphviz.jl")
include("graph/GraphState.jl")

include("executors/ExecutionEvent.jl")
include("executors/HistoricExecutor.jl")
include("executors/RealtimeExecutor.jl")

include("adapters/AdapterStorage.jl")
include("adapters/HistoricTimer.jl")
include("adapters/HistoricIterable.jl")
include("adapters/RealtimeTimer.jl")
include("adapters/RealtimeIterable.jl")

include("operations/Constant.jl")
include("operations/Func.jl")
include("operations/Print.jl")
include("operations/Copy.jl")
include("operations/Lag.jl")
include("operations/Buffer.jl")
include("operations/RingBuffer.jl")
include("operations/TimeTupleBuffer.jl")
include("operations/ForwardFill.jl")
include("operations/WindowBuffer.jl")
include("operations/TimeWindowBuffer.jl")
include("operations/TimeSampler.jl")

include("statistics/Counter.jl")
include("statistics/Diff.jl")
include("statistics/PctChange.jl")
include("statistics/LogPctChange.jl")
include("statistics/Mean.jl")
include("statistics/Median.jl")
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
include("statistics/ModifiedSinc.jl")
include("statistics/CumSum.jl")

include("encoders/PeriodicTimeEncoder.jl")
include("encoders/PeriodicWeekdayEncoder.jl")

# export all
for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include) && !startswith(string(n), "_")
        @eval export $n
    end
end

end
