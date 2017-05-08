export @named_term, @indexed_term, compile

"Convert a Julia lambda into a `Lambda`, keeping the names used"
macro named_term(expr::Expr) 
    return fromast_named(expr)
end

fromast_named(v::Symbol) = Expr(:call, :Var, Expr(:quote, v))

function fromast_named(expr::Expr)
    if expr.head == :call
        # TODO: handle :* case
        @assert(length(expr.args) >= 2, "call must contain arguments")
        mapfoldl(fromast_named, (f, arg) -> Expr(:call, :App, f, arg), expr.args)
    elseif expr.head == :->
        # TODO: handle multiple arguments
        @assert(isa(expr.args[1], Symbol), "only single-argument lambdas are allowed") 
        Expr(:call, :Abs, Expr(:quote, expr.args[1]), fromast_named(expr.args[2]))
    elseif expr.head == :$ && length(expr.args) == 1
        Expr(:call, :fromdebruijn, esc(expr.args[1]))
    elseif expr.head == :block
        # such trivial blocks are used by the parser in lambdas
        fromast_named(expr.args[end])
    else
        error("unhandled syntax: $expr)")
    end
end


"Convert a Julia lambda into an `IndexedLambda`"
macro indexed_term(expr::Expr)
    return fromast_indexed(expr)[1]
end

function fromast_indexed(v::Symbol, bound_names::Vector{Symbol} = Symbol[])
    i = findfirst(bound_names, v)
    if i != 0
        Expr(:call, :IVar, i, Expr(:quote, v)), bound_names
    else # free variable found
        Expr(:call, :IVar, length(bound_names) + 1, Expr(:quote, v)), [bound_names; v]
    end
end

function foldargs(args, bound_names)
    processed_args = Array(Expr, length(args))
    new_names = bound_names
    for (i, arg) in enumerate(args)
        expr, new_names = fromast_indexed(arg, new_names)
        processed_args[i] = expr
    end
    processed_args, new_names
end

function fromast_indexed(expr::Expr, bound_names::Vector{Symbol} = Symbol[])
    if expr.head == :call
        # TODO: handle :* case
        @assert(length(expr.args) >= 2, "call must contain arguments")
        args, new_names = foldargs(expr.args, bound_names)
        foldl((f, arg) -> Expr(:call, :IApp, f, arg), args), new_names
    elseif expr.head == :->
        # TODO: handle multiple arguments
        @assert(isa(expr.args[1], Symbol), "only single-argument lambdas are allowed")
        body, new_names = fromast_indexed(expr.args[2], [expr.args[1]; bound_names])
        Expr(:call, :IAbs, body, Expr(:quote, expr.args[1])), setdiff(new_names, [expr.args[1]])
    elseif expr.head == :$ && length(expr.args) == 1
        Expr(:call, :todebruijn, esc(expr.args[1])), bound_names
    elseif expr.head == :block
        # such trivial blocks are used by the parser in lambdas
        fromast_indexed(expr.args[end], bound_names)
    else
        error("unhandled syntax: $expr)")
    end
end

    
# conversion to Julia ast
toast(expr::Abs)::Expr = Expr(:->, Symbol(expr.variable), toast(expr.body))
toast(expr::App)::Expr = Expr(:call, toast(expr.car), toast(expr.cdr))
toast(expr::Var)::Symbol = Symbol(expr.name)

compile(expr::Lambda) = toast(expr) |> eval
compile(expr::IndexedLambda) = fromdebruijn(expr) |> toast |> eval
