"""
Updates the passed value with the latest value from the pipeline.
This allows to hook into a point in the pipeline and extract
intermediate values.
"""
struct OpHook{In,Next<:Union{Nothing,Op}} <: Op
    next::Next
    ref::Ref{In}

    OpHook(ref::Ref{In}) where {In} = new{In,Nothing}(nothing, ref)
    OpHook(ref::Ref{In}, next::Next) where {In,Next<:Union{Nothing,Op}} =
        new{In,Next}(next, ref)
end

@inline (op::OpHook)(value) = begin
    op.ref[] = value # update the reference value
    op.next(value)
end
