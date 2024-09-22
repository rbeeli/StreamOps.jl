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

"""
The input node is not passed as a parameter.
"""
struct NoBind <: ParamsBinding
end
