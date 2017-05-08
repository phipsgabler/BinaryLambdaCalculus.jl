module BinaryLambdaCalculus

using Iterators

import Base


######################
# DEFINITIONS OF TERMS
######################

export Lambda, Abs, App, Var
export IndexedLambda, IAbs, IApp, IVar
export stripnames, alpha_equivalent


"Representation of named lambda terms."
abstract Lambda

immutable Abs <: Lambda
    variable::Symbol
    body::Lambda
end

immutable App <: Lambda
    car::Lambda
    cdr::Lambda
end

immutable Var <: Lambda
    name::Symbol
end


"Representation of De Bruijn indexed lambda terms."
abstract IndexedLambda

typealias Index Int

immutable IAbs <: IndexedLambda
    body::IndexedLambda
    binding::Nullable{Symbol}
end

IAbs(body::IndexedLambda) = IAbs(body, Nullable{Symbol}())

immutable IApp <: IndexedLambda
    car::IndexedLambda
    cdr::IndexedLambda
end

immutable IVar <: IndexedLambda
    index::Index
    name::Nullable{Symbol}

    IVar(i, s) = i > 0 ? new(i, Nullable{Symbol}(s)) : error("De Bruijn index must be greater zero")
    IVar(i) = i > 0 ? new(i, Nullable{Symbol}()) : error("De Bruijn index must be greater zero")
end


Base.show(io::IO, expr::Abs) = print(io, "(λ$(expr.variable).$(expr.body))")
Base.show(io::IO, expr::App) = print(io, "($(expr.car) $(expr.cdr))")
Base.show(io::IO, expr::Var) = print(io, expr.name)

function Base.show(io::IO, expr::IAbs)
    if isnull(expr.binding)
        print(io, "(λ.$(expr.body))")
    else
        print(io, "(λ{$(get(expr.binding))}.$(expr.body))")
    end
end
Base.show(io::IO, expr::IApp) = print(io, "($(expr.car) $(expr.cdr))")
function Base.show(io::IO, expr::IVar)
    if isnull(expr.name)
        print(io, expr.index)
    else
        print(io, "{$(get(expr.name)):$(expr.index)}")
    end
end


@doc "Strip the implicitely remembered names of an indexed term" stripnames
stripnames(expr::IVar) = IVar(expr.index)
stripnames(expr::IAbs) = IAbs(stripnames(expr.body))
stripnames(expr::IApp) = IApp(stripnames(expr.car), stripnames(expr.cdr))

alpha_equivalent(t1::Lambda, t2::Lambda) = stripnames(todebruijn(t1)) == stripnames(todebruijn(t2))
alpha_equivalent(t1::IndexedLambda, t2::IndexedLambda) = stripnames(t1) == stripnames(t2)


############################
# CONVERSION JULIA <-> TERMS
############################
export @named_term, @indexed_term, compile

"Convert a Julia lambda into a `Lambda`, keeping the names used"
macro named_term(expr::Expr) 
    return fromast(expr)
end

"Convert a Julia lambda into an `IndexedLambda`"
macro indexed_term(expr::Expr)
    # TODO: maybe remember the names in a private field
    return :($(fromast(expr)) |> todebruijn)
end

fromast(v::Symbol) = Expr(:call, :Var, Expr(:quote, v))

# macro eval(ex)
#     :(eval($(current_module()), $(Expr(:quote,ex))))

function fromast(expr::Expr)
    if expr.head == :call
        # TODO: handle :* case
        # return foldl(App, map(fromast, expr.args))
        @assert(length(expr.args) >= 2, "call must contain arguments")
        return mapfoldl(fromast, (f, arg) -> Expr(:call, :App, f, arg), expr.args)
    elseif expr.head == :->
        @assert(isa(expr.args[1], Symbol), "only single-argument lambdas are allowed") # TODO: handle multiple arguments
        return Expr(:call, :Abs, Expr(:quote, expr.args[1]), fromast(expr.args[2]))
    # elseif expr.head == :$
        # esc
    elseif expr.head == :block
        # such trivial blocks are used by the parser in lambdas
        return fromast(expr.args[end])
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


############################################
# CONVERSION NAMED TERMS <-> DE BRUIJN TERMS
############################################

include("debruijn.jl")


####################################
# ENCODING/DECODING OF INDEXED TERMS
####################################

include("coding.jl")


#############################
# COUNTING/UNRANKING OF TERMS
#############################

include("tromp.jl")


####################################
# EVALUATING TERMS
####################################

include("evaluation.jl")

end
