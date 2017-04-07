module BinaryLambdaCalculus

using Iterators

import Base


######################
# DEFINITIONS OF TERMS
######################

export Lambda, Abs, App, Var
export IndexedLambda, IAbs, IApp, IVar


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

immutable IAbs <: IndexedLambda
    body::IndexedLambda
end

immutable IApp <: IndexedLambda
    car::IndexedLambda
    cdr::IndexedLambda
end

immutable IVar <: IndexedLambda
    index::UInt

    IVar(i) = i > 0 ? new(i) : error("De Bruijn index must be greater zero")
end


Base.show(io::IO, expr::Abs) = print(io, "(λ$(expr.variable).$(expr.body))")
Base.show(io::IO, expr::App) = print(io, "($(expr.car) $(expr.cdr))")
Base.show(io::IO, expr::Var) = print(io, expr.name)

Base.show(io::IO, expr::IAbs) = print(io, "(λ.$(expr.body))")
Base.show(io::IO, expr::IApp) = print(io, "($(expr.car) $(expr.cdr))")
Base.show(io::IO, expr::IVar) = print(io, expr.index)


# convenience macros for writing that stuff in better syntax
export @named_term, @indexed_term, compile

"Convert a Julia lambda into a `Lambda`, keeping the names used."
macro named_term(expr) 
    return fromast(expr)
end

"Convert a Julia lambda into an `IndexedLambda`, discarding the names used."
macro indexed_term(expr)
    # TODO: maybe remember the names in a private field
    return todebruijn(fromast(expr))
end

fromast(v::Symbol)::Lambda = Var(v)

function fromast(expr::Expr)::Lambda
    if expr.head == :call
        return foldl(App, map(fromast, expr.args))
    elseif expr.head == :->
        return Abs(expr.args[1], fromast(expr.args[2]));
    elseif expr.head == :block && length(expr.args) == 2
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


###########################################
# CONVERSION NAMED TERMS -> DE BRUIJN TERMS
###########################################

# the conversions functions are mostly a translation of this code:
# https://gist.github.com/Cedev/087c3e50ecc53e0f04e9,
# extended to work with an infinite reservoir of free variables

# NOTE: the De Bruijn indices begin at 1, not 0!

export todebruijn

"""
   todebruijn(expr::Lambda)::IndexedLambda 

Convert a named term into its De Bruijn representation.
"""
todebruijn(expr::Lambda)::IndexedLambda = todebruijn_helper(expr, collect(freevars(expr)))


function todebruijn_helper(expr::Var, names)::IndexedLambda
    i = findfirst(names, expr.name)
    return IVar(i)
end

function todebruijn_helper(expr::Abs, names)::IndexedLambda
    body = todebruijn_helper(expr.body, [expr.variable; names])
    return IAbs(body)
end

function todebruijn_helper(expr::App, names)::IndexedLambda
    l = todebruijn_helper(expr.car, names)
    r = todebruijn_helper(expr.cdr, names)
    return IApp(l, r)
end

freevars(expr::Var)::Set{Symbol} = Set([expr.name])
freevars(expr::Abs)::Set{Symbol} = setdiff(freevars(expr.body), Set([expr.variable]))
freevars(expr::App)::Set{Symbol} = union(freevars(expr.car), freevars(expr.cdr))


###########################################
# CONVERSION DE BRUIJN TERMS -> NAMED TERMS
###########################################

# NOTE: indices begin at 1, not 0!

export fromdebruijn

include("namesgenerator.jl")


"""
    fromdebruijn(expr::IndexedLambda[, tag::String])::Lambda

Convert an indexed term to a named term.  If free variables occur, they are given new, unique names,
based on `tag`.
"""
function fromdebruijn(expr::IndexedLambda, tag::String = "x")::Lambda
    return fromdebruijn_helper(expr, generatenames(tag), [])
end


"""
    fromdebruijn(expr::IndexedLambda, names)::Lambda

Convert an indexed term to a named term. If free variables occur, they are given new, unique names
based on the given `names`; these are suffixed, if not sufficient.
"""
function fromdebruijn(expr::IndexedLambda, names)::Lambda
    return fromdebruijn_helper(expr, generatenames(names), [])
end


# TODO: turn used_names into a tree?

function fromdebruijn_helper(expr::IVar, available_names, used_names)::Lambda
    level = length(used_names)
    
    if 1 <= expr.index <= level
        return Var(used_names[expr.index])
    elseif level < expr.index
        return Var(nth(available_names, expr.index - level))
    else
        error("Invalid index: $(expr.index)")
    end
end

function fromdebruijn_helper(expr::IAbs, available_names, used_names)::Lambda
    new_name = nth(available_names, 1)
    body = fromdebruijn_helper(expr.body, drop(available_names, 1), [new_name; used_names])
    return Abs(new_name, body)
end

function fromdebruijn_helper(expr::IApp, available_names, used_names)::Lambda
    l = fromdebruijn_helper(expr.car, available_names, used_names)
    r = fromdebruijn_helper(expr.cdr, available_names, used_names)
    return App(l, r)
end


####################################
# ENCODING/DECODING OF INDEXED TERMS
####################################

include("coding.jl")

#############################
# COUNTING/UNRANKING OF TERMS
#############################

include("tromp.jl")


end
