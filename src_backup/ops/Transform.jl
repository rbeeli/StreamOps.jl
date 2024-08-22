"""
Transforms the input value using the provided function and its return value.
"""
struct Transform{F}
    fn::F
    Transform(fn::F) where {F} = new{F}(fn)
end

@inline (op::Transform)(value) = op.fn(value)
