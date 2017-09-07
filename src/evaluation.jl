export evaluate, evaluateonce, @evaluate

shift(c, d, expr::IVar) = (expr.index < c) ? expr : IVar(expr.index + d, expr.name)
shift(c, d, expr::IAbs) = IAbs(shift(c + 1, d, expr.body), expr.binding)
shift(c, d, expr::IApp) = IApp(shift(c, d, expr.car), shift(c, d, expr.cdr))
shift(d, expr::IndexedLambda) = shift(1, d, expr)

substitute(expr::IVar, x::IVar, s::IndexedLambda) = (expr.index == x.index) ? s : expr
substitute(expr::IAbs, x::IVar, s::IndexedLambda) =
    IAbs(substitute(expr.body, IVar(x.index + 1, x.name), shift(1, s)), expr.binding)
substitute(expr::IApp, x::IVar, s::IndexedLambda) =
    IApp(substitute(expr.car, x, s), substitute(expr.cdr, x, s))

# (k::IndexedLambda)(subs::Pair{Int, IndexedLambda}) = substitute(subs.first, subs.second, k)

@compat abstract type EvalResult end

@compat struct Redex <: EvalResult
    expr::IndexedLambda
end

@compat struct Irreducible <: EvalResult
    expr::IndexedLambda
end


function evaluateonce_app(car::IVar, cdr::IndexedLambda)
    newcdr = evaluateonce(cdr)
    if isa(newcdr, Redex)
        Redex(IApp(car, newcdr.expr))
    else
        Irreducible(IApp(car, newcdr.expr))
    end
end

evaluateonce_app(car::IAbs, cdr::IndexedLambda) =
    Redex(shift(-1, substitute(car.body, IVar(1), shift(1, cdr))))

function evaluateonce_app(car::IApp, cdr::IndexedLambda)
    newcar = evaluateonce(car)
    if isa(newcar, Redex)
        Redex(IApp(newcar.expr, cdr))
    else
        Irreducible(IApp(newcar.expr, cdr))
    end
end


@doc "Reduce an indexed term by one step in normal order" evaluateonce
evaluateonce(expr::IApp) = evaluateonce_app(expr.car, expr.cdr)
evaluateonce(expr::IVar) = Irreducible(expr)
function evaluateonce(expr::IAbs)
    newbody = evaluateonce(expr.body)
    if isa(newbody, Redex)
        Redex(IAbs(newbody.expr, expr.binding))
    else
        Irreducible(IAbs(newbody.expr, expr.binding))
    end
end


"""
    evaluate(expr::IndexedLambda[, steps::Int])

Evaluate an indexed term by normal order reduction, using maximally `steps` reductions.
"""
function evaluate(expr::IndexedLambda, steps::Int)
    while steps >= 0
        reduced = evaluateonce(expr)
        isa(expr, Irreducible) && break
        expr = reduced.expr
        steps -= 1
    end

    expr
end

function evaluate(expr::IndexedLambda)
    reduced = evaluateonce(expr)

    while isa(reduced, Redex)
        reduced = evaluateonce(reduced.expr)
    end

    reduced.expr
end

evaluate(expr::Lambda) = evaluate(todebruijn(expr))
evaluate(expr::Lambda, steps::Int) = evaluate(todebruijn(expr), steps)

macro evaluate(expr)
    :(evaluate($(expr2ast(expr))))
end

macro evaluate(expr, n)
    :(evaluate($(expr2ast(expr)), $n))
end

