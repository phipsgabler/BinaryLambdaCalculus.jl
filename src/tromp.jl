# Implementations of combinatorial functions from "Counting and Generating Terms in the Binary
# Lambda Calculus".

import Base

export tromp, tromp!, unrank, unrank!, terms

# TODO:
# - make k start from 0
# - adapt getindex of TermsIterator


########################
# COUNTING AND UNRANKING
########################

const Table{T} = Dict{Tuple{Int, Int}, T}


"""
     tromp{T}(m::Integer, n::Integer[, ::Type{T}])::T

Calculate the number of De Bruijn terms of binary size `n`, with at most `m` free variables.  This
corresponds to the series Sₘₙ from [this paper](https://arxiv.org/pdf/1511.05334v1.pdf).
"""
function tromp(m::Integer, n::Integer, ::Type{T} = Int) where {T<:Integer}
    return tromp!(m, n, Table{T}())
end


"""
    tromp!{T}(m::Integer, n::Integer, table::Table{T})::T

Calculate the number of de Bruijn terms of binary size `n`, with at most `m` free variables.  This
corresponds to the series Sₘₙ from [this paper](https://arxiv.org/pdf/1511.05334v1.pdf).

As a side effect, fill `table` with recursive calls whose entries correspond to `tromp(n, m)`.  This
method should be used instead of repeatedly calling `tromp`.
"""
function tromp!(m::Integer, n::Integer, table::Table{T}) where {T<:Integer}
    @assert(m >= 0)
    @assert(n >= 0)

    # Sₘ₀ = Sₘ₁ = 0
    # Sₘₙ = [m ≥ n - 1] + Sₘ₊₁,ₙ₋₂ + ∑_{k=0}^{n-2} Sₘ,k Sₘ,ₙ₋₂₋ₖ
    get!(table, (m, n)) do
        if n <= 1
            return 0
        else 
            Int(m >= n - 1) +
                tromp!(m + 1, n - 2, table) +
                sum(tromp!(m, k, table) * tromp!(m, n - 2 - k, table) for k = 0:(n-2))
        end
    end
end


"""
    unrank{T}(m::Integer, n::Integer, k::Integer[, ::Type{T}])::IndexedLambda

Calculate the `k`-th De Bruijn term of binary size `n`, with at most `m` free variables (indices
start at 1).
"""
function unrank(m::Integer, n::Integer, k::Integer, ::Type{T} = Int) where {T<:Integer}
    unrank!(m, n, k, Table{T}())
end


"""
    unrank!{T}(m::Integer, n::Integer, k::Integer, table::Table{T})::IndexedLambda

Calculate the `k`-th De Bruijn term of binary size `n`, with at most `m` free variables,
using tabulated values for Sₙₘ.

This function should be used for repeated unrankings, so that the series Sₙₘ does
not have to be recomputed every time.
"""
function unrank!(m::Integer, n::Integer, k::Integer, table::Table{T}) where {T<:Integer}
    @assert(m >= 0)
    @assert(n >= 0)
    @assert(k >= 1)

    t = tromp!(m, n, table)
    @assert(t >= k)
    
    if m >= n - 1 && k == t
        return Var(n - 1)
    elseif k <= tromp!(m + 1, n - 2, table)
        return Abs(unrank!(m + 1, n - 2, k, table))
    else
        return unrank_app!(m, n - 2, 0, k - tromp!(m + 1, n - 2, table), table)
    end
end


function unrank_app!(m::Integer, n::Integer, j::Integer, r::Integer,
                     table::Table{T}) where {T<:Integer}
    tmnj = tromp!(m, n - j, table)
    tmjtmnj = tromp!(m, j, table) * tmnj

    if r <= tmjtmnj
        dv, rm = divrem(r - 1, tmnj)
        return App(unrank!(m, j, dv + 1, table), unrank!(m, n - j, rm + 1, table))
    else
        return unrank_app!(m, n, j + 1, r - tmjtmnj, table)
    end
end


#################
# ITERATING TERMS
#################

"""
    terms(m::Integer, n::Integer[, ::Type{T}])

An iterator for all de Bruijn terms of size `n` with at most `m` free variables.
"""
function terms(m, n, ::Type{T} = Int) where {T<:Integer}
    @assert(m >= 0)
    @assert(n >= 0)

    table = Table{T}()
    tromp!(m, n, table)
    TermsIterator{T}(m, n, table)
end


struct TermsIterator{T<:Integer}
    m::Int
    n::Int
    table::Table{T}
end

function Base.iterate(iter::TermsIterator, state = 1)
    if state ≤ iter.table[(iter.m, iter.n)]
        return (unrank!(iter.m, iter.n, state, iter.table), state + 1)
    else
        return nothing
    end
end

Base.IteratorSize(::Type{<:TermsIterator}) = Base.HasLength()
Base.length(iter::TermsIterator) = iter.table[(iter.m, iter.n)]
Base.IteratorEltype(::Type{<:TermsIterator}) = Base.HasEltype()
Base.eltype(::Type{<:TermsIterator}) = Term

Base.getindex(iter::TermsIterator, i::Integer) = unrank!(iter.m, iter.n, i, iter.table)
Base.firstindex(iter::TermsIterator) = 1
Base.lastindex(iter::TermsIterator) = tromp!(iter.m, iter.n, iter.table)
