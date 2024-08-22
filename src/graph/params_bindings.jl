"""
The input nodes are passed as parameter according to their position in the input list.
"""
struct PositionParams <: ParamsBinding
end

"""
The input nodes are passed as keyword parameters.
"""
struct NamedParams <: ParamsBinding
end

"""
The input nodes are passed as a single tuple parameter.
"""
struct TupleParams <: ParamsBinding
end
