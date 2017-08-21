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
abstract type Lambda end

struct Abs <: Lambda
    variable::Symbol
    body::Lambda
end

struct App <: Lambda
    car::Lambda
    cdr::Lambda
end

struct Var <: Lambda
    name::Symbol
end


"Representation of De Bruijn indexed lambda terms."
abstract type IndexedLambda end

const Index =  Int

struct IAbs <: IndexedLambda
    body::IndexedLambda
    binding::Nullable{Symbol}
end

IAbs(body::IndexedLambda) = IAbs(body, Nullable{Symbol}())

struct IApp <: IndexedLambda
    car::IndexedLambda
    cdr::IndexedLambda
end

struct IVar <: IndexedLambda
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

include("meta.jl")


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


################
# REDUCING TERMS
################

include("evaluation.jl")

end
