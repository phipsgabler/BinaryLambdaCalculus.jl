module BLC

using Lazy
using PEGParser

import Base

######################
# DEFINITIONS OF TERMS
######################

export Lambda, Abs, App, Var
export IndexedLambda, IAbs, IApp, IVar

abstract Lambda

immutable Abs <: Lambda
    variable :: AbstractString
    body :: Lambda
end

immutable App <: Lambda
    car :: Lambda
    cdr :: Lambda
end

immutable Var <: Lambda
    name :: AbstractString
end
    

abstract IndexedLambda

immutable IAbs <: IndexedLambda
    body :: IndexedLambda
end

immutable IApp <: IndexedLambda
    car :: IndexedLambda
    cdr :: IndexedLambda
end

immutable IVar <: IndexedLambda
    name :: Integer
end


Base.string(expr::Abs) = "(λ$(expr.variable)." * string(expr.body) * ")"
Base.string(expr::App) = "($(string(expr.car)) $(string(expr.cdr)))"
Base.string(expr::Var) = expr.name
Base.show(io::IO, expr::Lambda) = print(io, string(expr))
#Base.print(io::IO, expr::Lambda) = print(io, string(expr))

Base.string(expr::IAbs) = "(λ." * string(expr.body) * ")"
Base.string(expr::IApp) = "$(string(expr.car)) $(string(expr.cdr))"
Base.string(expr::IVar) = string(expr.name)
Base.show(io::IO, expr::IndexedLambda) = print(io, string(expr))
#Base.print(io::IO, expr::IndexedLambda) = print(io, string(expr))

# convenience macros for writing that stuff in better syntax
export @named_term, @indexed_term

macro named_term(expr) 
    return :($(toast(expr)))
end

macro indexed_term(expr)
    return :($(todebruijn(toast(expr))))
end

toast(v :: Symbol) = Var(string(v))

function toast(expr :: Expr)
    if expr.head == :call
        return foldl(App, map(toast, expr.args))
    elseif expr.head == :->
        return Abs(string(expr.args[1]), toast(expr.args[2]));
    elseif expr.head == :block && length(expr.args) == 2
        # such trivial blocks are  used by the parser in lambdas
        return toast(expr.args[end])
    else
        error("unhandled syntax: $expr)")
    end
end


###########################################
# CONVERSION NAMED TERMS -> DE BRUIJN TERMS
###########################################

# NOTE: indices begin at 1, not 0!

export todebruijn

todebruijn(expr :: Lambda) = todebruijn_helper(expr, collect(freevars(expr)))


function todebruijn_helper(expr :: Var, names)
    i = findfirst(names, expr.name)
    return IVar(i)
end

function todebruijn_helper(expr :: Abs, names)
    body = todebruijn_helper(expr.body, [expr.variable; names])
    return IAbs(body)
end

function todebruijn_helper(expr :: App, names)
    l = todebruijn_helper(expr.car, names)
    r = todebruijn_helper(expr.cdr, names)
    return IApp(l, r)
end

freevars(expr :: Var) = Set([expr.name])
freevars(expr :: Abs) = setdiff(freevars(expr.body), Set([expr.variable]))
freevars(expr :: App) = union(freevars(expr.car), freevars(expr.cdr))


###########################################
# CONVERSION DE BRUIJN TERMS -> NAMED TERMS
###########################################

# NOTE: indices begin at 1, not 0!

export fromdebruijn

function fromdebruijn(expr :: IndexedLambda)
    available_names = @lazy Lazy.repeatedly(() -> string(gensym()))
    return fromdebruijn_helper(expr, available_names, [])
end

function fromdebruijn(expr :: IndexedLambda, names)
    available_names = @lazy Lazy.seq(names) * makenames(names, 0)
    return fromdebruijn_helper(expr, available_names, [])
end


function fromdebruijn_helper(expr :: IVar, available_names, used_names)
    level = length(used_names)
    return if 1 <= expr.name <= level
        return Var(used_names[expr.name])
    elseif level < expr.name
        return Var(available_names[expr.name - level])
    else
        error("invalid index")
    end
end

function fromdebruijn_helper(expr :: IAbs, available_names, used_names)
    new_name = available_names[1]
    body = fromdebruijn_helper(expr.body,
                               Lazy.drop(1, available_names),
                               [new_name; used_names])
    return Abs(new_name, body)
end

function fromdebruijn_helper(expr :: IApp, available_names, used_names)
    l = fromdebruijn_helper(expr.car, available_names, used_names)
    r = fromdebruijn_helper(expr.cdr, available_names, used_names)
    return App(l, r)
end

makenames(names, i::Integer) = @lazy Lazy.map(n -> n * string(i), names) * makenames(names, i+1)

####################################
# ENCODING/DECODING OF INDEXED TERMS
####################################

export encode, decode

encode(var :: IVar) = "\x01" ^ var.name * "\0"
encode(abs :: IAbs) = "\0\0" * encode(abs.body)
encode(app :: IApp) = "\0\x01" * encode(app.car) * encode(app.cdr)


@grammar blc begin
    start = term{ _1 }
    term = var | abs | app 
    var = (+("\x01") + "\0"){ IVar(length(_1.value)) }
    abs = ("\0\0" + term){ IAbs(_2) }
    app = ("\0\x01" + term + term){ IApp(_2, _3) }
end

function decode(bytes :: AbstractString, onerror = e -> nothing)
    parser_result = parse(blc, bytes)
    if parser_result[3] == nothing
        return Nullable(parser_result[1])
    else
        onerror(parser_result[3])
        return Nullable{IndexedLambda}()
    end
end


#############################
# COUNTING/UNRANKING OF TERMS
#############################

export tromp, unrank, terms

include("tromp.jl")


end
