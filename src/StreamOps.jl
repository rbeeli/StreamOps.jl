module StreamOps

include("utils.jl")
include("types.jl")

include("graph/call_policies.jl")
include("graph/params_bindings.jl")
include("graph/InputBinding.jl")
include("graph/StreamNode.jl")
include("graph/StreamGraph.jl")

include("executors/ExecutionEvent.jl")
include("executors/HistoricExecutor.jl")
include("executors/RealtimeExecutor.jl")

include("sources/SourceStorage.jl")
include("sources/TimerSource.jl")
include("sources/LiveTimerSource.jl")
include("sources/IterableAdapter.jl")

include("operations/Func.jl")
include("operations/Copy.jl")
include("operations/Lag.jl")
include("operations/Buffer.jl")
include("operations/WindowBuffer.jl")

include("statistics/Counter.jl")
include("statistics/Diff.jl")
include("statistics/PctChange.jl")
include("statistics/Mean.jl")

# export all
for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end
