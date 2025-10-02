"""
    Helper utilities for macro argument normalization.
"""
_extract_symbol(x) = x isa Symbol ? x : x isa QuoteNode ? x.value : error("Expected Symbol literal like :name, got $(x)")

function _normalize_sources(s)
    if s isa Symbol
        return s
    elseif s isa QuoteNode
        return s.value
    elseif s isa Expr && s.head == :tuple
        return Expr(:tuple, (_extract_symbol(a) for a in s.args)...)
    else
        return s   # allow already well-formed complex expressions
    end
end

function _quote_sources(s)
    if s isa Symbol
        return QuoteNode(s)
    elseif s isa Expr && s.head == :tuple
        return Expr(:tuple, (QuoteNode(a) for a in s.args)...)
    else
        return s  # leave complex expressions (e.g., already quoted) untouched
    end
end

function _parse_binding(args::Vector)
    if !isempty(args) && args[1] isa Expr
        ex = args[1]
        if ex.head == :call && ex.args[1] == :(=>) && length(ex.args) == 3
            return true, _normalize_sources(ex.args[2]), _extract_symbol(ex.args[3]), args[2:end]
        end
    end
    return false, nothing, nothing, args
end

"""
    @sink g :dest OpExpr
    @sink g :src => :dest OpExpr

Create a sink (sink!) and optionally bind a source to it.

Examples:
    @sink g :VIX9D_daily_collector TimeTupleBuffer{DateTime,Float64}()
    @sink g :VIX9D_daily => :VIX9D_daily_collector TimeTupleBuffer{DateTime,Float64}()

Returns the destination Symbol.
"""
macro sink(g, args...)
    args_vec = collect(args)
    has_binding, src_expr, dest_sym, rest = _parse_binding(args_vec)

    op_expr = nothing
    extra = Any[]
    if has_binding
        !isempty(rest) || error("@sink: missing OpExpr after binding spec")
        op_expr = rest[1]
        extra = rest[2:end]
    else
        length(rest) >= 2 || error("@sink: need (:dest OpExpr) or (:src => :dest OpExpr)")
        dest_sym = _extract_symbol(rest[1])
        op_expr = rest[2]
        extra = rest[3:end]
    end

    bind_kw_pairs = Expr[]
    for ex in extra
        if ex isa Expr && ex.head == :(=)
            push!(bind_kw_pairs, ex)
        else
            error("@sink: unexpected argument $(ex)")
        end
    end

    !has_binding && !isempty(bind_kw_pairs) &&
        error("@sink: bind keyword arguments require a source binding (use =>)")

    sink_call = Expr(:call, :sink!, esc(g), QuoteNode(dest_sym), esc(op_expr))
    block = Expr(:block, sink_call)
    if has_binding
        bind_kw_exprs = [Expr(:kw, kw.args[1], esc(kw.args[2])) for kw in bind_kw_pairs]
        params = isempty(bind_kw_exprs) ? nothing : Expr(:parameters, bind_kw_exprs...)
        src_arg = _quote_sources(src_expr)
        bind_call_args = Any[:bind!]
        if params !== nothing
            push!(bind_call_args, params)
        end
        append!(bind_call_args, (esc(g), src_arg, QuoteNode(dest_sym)))
        bind_call = Expr(:call, bind_call_args...)
        push!(block.args, bind_call)
    end
    push!(block.args, QuoteNode(dest_sym))
    return block
end

"""
    @op g :dest OpExpr out=Type
    @op g :src => :dest OpExpr out=Type [bind kwargs...]
    @op g (:s1, :s2, ...) => :dest OpExpr out=Type [bind kwargs...]

Create an operation via op! and optionally bind source(s).

Mandatory:
    out=Type  (return type for op!)

Binding kwargs (forwarded to bind!):
    call_policies=...
    bind_as=...
    any other keyword accepted by bind!

Examples:
    @op g :VIX9D_daily Func((exe, v)->v, NaN, is_valid=isfinite) out=Float64
    @op g :close_ind => :VIX9D_daily Func((exe,v)->v, NaN) out=Float64 call_policies=[IfExecuted(:close_ind)]
    @op g (:A,:B) => :C Func((exe,a,b)->a+b, 0.0) out=Float64 call_policies=[IfExecuted(:all), IfValid(:all)]
"""
macro op(g, args...)
    args_vec = collect(args)
    # Detect binding spec
    has_binding, sources_expr, dest_sym, rest = _parse_binding(args_vec)

    op_expr = nothing
    extra = Any[]
    if has_binding
        !isempty(rest) || error("@op: missing OpExpr after binding spec")
        op_expr = rest[1]
        extra = rest[2:end]
    else
        length(args_vec) >= 2 || error("@op: need :dest OpExpr ...")
        dest_sym = _extract_symbol(args_vec[1])
        op_expr = args_vec[2]
        extra = args_vec[3:end]
    end

    out_type = nothing
    bind_kw_pairs = Expr[]
    for ex in extra
        if ex isa Expr && ex.head == :(=) && ex.args[1] == :out
            out_type === nothing || error("@op: duplicate out=")
            out_type = ex.args[2]
        elseif ex isa Expr && ex.head == :(=)
            push!(bind_kw_pairs, ex)
        else
            error("@op: unexpected argument $(ex)")
        end
    end
    out_type === nothing && error("@op: missing mandatory out=Type")

    # Build op! call with keyword
    op_kw = Expr(:parameters, Expr(:kw, :out, esc(out_type)))
    op_call = Expr(:call, :op!, op_kw, esc(g), QuoteNode(dest_sym), esc(op_expr))

    block = Expr(:block, op_call)
    if has_binding
        src_arg = _quote_sources(sources_expr)
        bind_kw_exprs = [Expr(:kw, kw.args[1], esc(kw.args[2])) for kw in bind_kw_pairs]
        bind_call_args = Any[:bind!]
        if !isempty(bind_kw_exprs)
            push!(bind_call_args, Expr(:parameters, bind_kw_exprs...))
        end
        append!(bind_call_args, (esc(g), src_arg, QuoteNode(dest_sym)))
        bind_call = Expr(:call, bind_call_args...)
        push!(block.args, bind_call)
    end
    push!(block.args, QuoteNode(dest_sym))
    return block
end

"""
    @bind g :src => :dest [bind kwargs...]
    @bind g (:s1, :s2) => :dest [bind kwargs...]

Bind existing nodes. For tuple sources the tuple form is passed directly.

Examples:
    @bind g :A => :B call_policies=Never()
    @bind g (:A,:B) => :C call_policies=[IfExecuted(:all), IfValid(:all)]
"""
macro bind(g, spec, rest...)
    # Expect spec == :src => :dest (parsed as Expr(:call, :(=>), src, dest))
    spec isa Expr && spec.head == :call && !isempty(spec.args) && spec.args[1] == :(=>) && length(spec.args) == 3 || error("@bind: require :src => :dest or (sources...) => :dest")
    src_expr = _normalize_sources(spec.args[2])
    dest_sym = _extract_symbol(spec.args[3])

    bind_kws = Expr[]
    for ex in rest
        if ex isa Expr && ex.head == :(=)
            push!(bind_kws, ex)
        else
            error("@bind: unexpected token $(ex)")
        end
    end
    bind_kw_exprs = [Expr(:kw, kw.args[1], esc(kw.args[2])) for kw in bind_kws]
    bind_kwargs_expr = isempty(bind_kw_exprs) ? nothing : Expr(:parameters, bind_kw_exprs...)

    src_arg = _quote_sources(src_expr)
    bind_call_args = Any[:bind!]
    if bind_kwargs_expr !== nothing
        push!(bind_call_args, bind_kwargs_expr)
    end
    append!(bind_call_args, (esc(g), src_arg, QuoteNode(dest_sym)))
    bind_call = Expr(:call, bind_call_args...)
    return Expr(:block, bind_call, QuoteNode(dest_sym))
end

export @sink, @op, @bind
