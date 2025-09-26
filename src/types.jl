abstract type CallPolicy end

abstract type ParamsBinding end

abstract type StreamOperation end

abstract type GraphState end

abstract type GraphExecutor end

abstract type SourceAdapter end

## traits

# Tell executor to call update_time! on operation
# before execution of graph
abstract type OperationTimeSync end

# default = false
OperationTimeSync(::Any) = false

export CallPolicy,
    ParamsBinding, StreamOperation, GraphState, GraphExecutor, SourceAdapter, OperationTimeSync
