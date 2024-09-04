abstract type CallPolicy end

abstract type ParamsBinding end

abstract type StreamOperation end

abstract type StreamGraphState end

abstract type StreamGraphExecutor end

## traits
abstract type StreamOperationTimeSync end

StreamOperationTimeSync(::Any) = false
