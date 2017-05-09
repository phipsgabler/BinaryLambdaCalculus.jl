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

abstract EvalResult

immutable Redex <: EvalResult
    expr::IndexedLambda
end

immutable Irreducible <: EvalResult
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


"Evaluate an indexed term by normal order reduction"
evaluate(expr::IndexedLambda) = evaluate(evaluateonce(expr))
evaluate(expr::Lambda) = evaluate(todebruijn(expr))
evaluate(r::Redex) = evaluate(evaluateonce(r.expr))
evaluate(r::Irreducible) = r.expr

macro evaluate(expr)
    :(evaluate($(expr2ast(expr))))
end

