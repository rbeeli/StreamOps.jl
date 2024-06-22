"""
Updates the hook's `ref` value with the latest value from the pipeline.
The reference variable can be passed into the operation in the constructor.

This allows to hook into a pipeline and extract intermediate values.
"""
struct Hook{In}
    ref::Ref{In}

    Hook(
        ref::Ref{In}
    ) where {In} = new{In}(ref)
end

@inline (op::Hook)(value) = begin
    op.ref[] = value # update the reference value
    value
end
