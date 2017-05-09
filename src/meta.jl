export @named_term, @indexed_term, compile

# "expr" means a Julia expression: :(:-> :x :y)
# "lambda" means a Lambda value: Abs(:x, Var(:y))
# "ast" means a Julia expression for a lambda value: :(:call :Abs :(:x) (:call :Var :(:y)))

"Convert a Julia lambda into a `Lambda`, keeping the names used"
macro named_term(expr::Expr) 
    return expr2ast(expr)
end

expr2ast(v::Symbol) = Expr(:call, :Var, Expr(:quote, v))

function expr2ast(expr::Expr)
    if expr.head == :call
        # TODO: handle :* case
        @assert(length(expr.args) >= 2, "call must contain arguments")
        mapfoldl(expr2ast, (f, arg) -> Expr(:call, :App, f, arg), expr.args)
    elseif expr.head == :->
        # TODO: handle multiple arguments
        @assert(isa(expr.args[1], Symbol), "only single-argument lambdas are allowed") 
        Expr(:call, :Abs, Meta.quot(expr.args[1]), expr2ast(expr.args[2]))
    elseif expr.head == :$ && length(expr.args) == 1
        Expr(:call, :fromdebruijn, esc(expr.args[1]))
    elseif expr.head == :block
        # such trivial blocks are used by the parser in lambdas
        expr2ast(expr.args[end])
    else
        error("unhandled syntax: $expr)")
    end
end

"Convert a Julia lambda into an `IndexedLambda`"
macro indexed_term(expr::Expr)
    return :(todebruijn($(expr2ast(expr))))
end

    
# conversion to Julia ast
lambda2expr(expr::Abs)::Expr = Expr(:->, Symbol(expr.variable), lambda2expr(expr.body))
lambda2expr(expr::App)::Expr = Expr(:call, lambda2expr(expr.car), lambda2expr(expr.cdr))
lambda2expr(expr::Var)::Symbol = Symbol(expr.name)
lambda2expr(expr::IndexedLambda) = lambda2expr(fromdebruijn(expr))

compile(expr::Lambda) = lambda2expr(expr) |> eval
compile(expr::IndexedLambda) = fromdebruijn(expr) |> lambda2expr |> eval
