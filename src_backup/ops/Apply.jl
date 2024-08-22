"""
Applies arbitrary function to the input and returns the original input value.
"""
struct Apply{F}
    fn::F
    Apply(fn::F) where {F} = new{F}(fn)
end

@inline function (op::Apply)(value)
    op.fn(value)
    return value
end
