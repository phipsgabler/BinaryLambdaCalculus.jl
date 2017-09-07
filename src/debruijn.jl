# the conversions functions are mostly a translation of this code:
# https://gist.github.com/Cedev/087c3e50ecc53e0f04e9,
# extended to work with an infinite reservoir of free variables

# NOTE: the De Bruijn indices begin at 1, not 0!

using Base.Iterators: drop

export todebruijn

"""
   todebruijn(expr::Lambda)::IndexedLambda 

Convert a named term into its De Bruijn representation.
"""
todebruijn(expr::Lambda)::IndexedLambda = todebruijn_helper(expr, collect(freevars(expr)))
todebruijn(expr::IndexedLambda)::IndexedLambda = expr


function todebruijn_helper(expr::Var, names::Vector{Symbol})::IndexedLambda
    i = findfirst(names, expr.name)
    return IVar(i, expr.name)
end

function todebruijn_helper(expr::Abs, names::Vector{Symbol})::IndexedLambda
    body = todebruijn_helper(expr.body, [expr.variable; names])
    return IAbs(body, expr.variable)
end

function todebruijn_helper(expr::App, names::Vector{Symbol})::IndexedLambda
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

fromdebruijn(expr::Lambda)::Lambda = expr

"""
    fromdebruijn(expr::IndexedLambda[, tag::String])::Lambda

Convert an indexed term to a named term.  If free variables occur, they are given new, unique names,
based on `tag`.
"""
function fromdebruijn(expr::IndexedLambda, tag::AbstractString = "x")::Lambda
    return fromdebruijn_helper(expr, generatenames(tag), Symbol[])
end


"""
    fromdebruijn(expr::IndexedLambda, names)::Lambda

Convert an indexed term to a named term. If free variables occur, they are given new, unique names
based on the given `names`; these are suffixed, if not sufficient.
"""
function fromdebruijn(expr::IndexedLambda, names)::Lambda
    return fromdebruijn_helper(expr, generatenames(names), Symbol[])
end


"Generate a unique new name based on `name`, different form the `used_names`"
function pickname(name::Symbol, used_names::Vector{Symbol})::Symbol
    if name in used_names
        pickname(Symbol(string(name) * "\'"), used_names)
    else
        name
    end
end


function fromdebruijn_helper(expr::IVar, available_names, used_names::Vector{Symbol})::Lambda
    level = length(used_names)

    if 1 <= expr.index <= level # bound variable
        return Var(used_names[expr.index])
    elseif level < expr.index # free variable
        if isnull(expr.name)
            return Var(nth(available_names, expr.index - level))
        else
            return Var(pickname(get(expr.name), used_names))
        end
    else
        error("Invalid index: $(expr.index)")
    end
end

function fromdebruijn_helper(expr::IAbs, available_names, used_names::Vector{Symbol})::Lambda
    if isnull(expr.binding)
        new_name = nth(available_names, 1)
        body = fromdebruijn_helper(expr.body, drop(available_names, 1), [new_name; used_names])
        return Abs(new_name, body)
    else
        new_name = pickname(get(expr.binding), used_names)
        body = fromdebruijn_helper(expr.body, available_names, [new_name; used_names])
        return Abs(new_name, body)
    end
end

function fromdebruijn_helper(expr::IApp, available_names, used_names::Vector{Symbol})::Lambda
    l = fromdebruijn_helper(expr.car, available_names, used_names)
    r = fromdebruijn_helper(expr.cdr, available_names, used_names)
    return App(l, r)
end
