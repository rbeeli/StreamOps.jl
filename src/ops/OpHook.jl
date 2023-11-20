"""
Updates the passed value with the latest value from the pipeline.
This allows to hook into a point in the pipeline and extract
intermediate values.
"""
struct OpHook{In,Next<:Op} <: Op
    next::Next
    ref::Ref{In}

    OpHook(
        ref::Ref{In}
        ;
        next::Next=OpNone()
    ) where {In,Next<:Op} = new{In,Next}(next, ref)
end

@inline (op::OpHook)(value) = begin
    op.ref[] = value # update the reference value
    op.next(value)
end
