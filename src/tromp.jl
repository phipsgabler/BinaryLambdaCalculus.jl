# Implementations of combinatorial functions from "Counting and Generating Terms in the Binary
# Lambda Calculus".


export tromp, tromp!, unrank, unrank!, terms


########################
# COUNTING AND UNRANKING
########################

typealias Table{T} Dict{Tuple{Int, Int}, T}


"""
     tromp{T}(m::Integer, n::Integer[, ::Type{T}])::T

Calculate the number of De Bruijn terms of binary size `n`, with at most `m` free variables.  This
corresponds to the series Sₘₙ from [this paper](https://arxiv.org/pdf/1511.05334v1.pdf).
"""
function tromp{T<:Integer}(m::Integer, n::Integer, ::Type{T} = Int)::T
    return tromp!(m, n, Table{T}())
end


"""
    tromp!{T}(m::Integer, n::Integer, table::Table{T})::T

Calculate the number of de Bruijn terms of binary size `n`, with at most `m` free variables.  This
corresponds to the series Sₘₙ from [this paper](https://arxiv.org/pdf/1511.05334v1.pdf).

As a side effect, fill `table` with recursive calls whose entries correspond to `tromp(n, m)`.  This
method should be used instead of repeatedly calling `tromp`.
"""
function tromp!{T<:Integer}(m::Integer, n::Integer, table::Table{T})::T
    @assert(m >= 0)
    @assert(n >= 0)

    # Sₘ₀ = Sₘ₁ = 0
    # Sₘₙ = [m ≥ n - 1] + Sₘ₊₁,ₙ₋₂ + ∑_{k=0}^{n-2} Sₘ,k Sₘ,ₙ₋ₖ
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
function unrank{T<:Integer}(m::Integer, n::Integer, k::Integer, ::Type{T} = Int)::IndexedLambda
    unrank!(m, n, k, Table{T}())
end


"""
    unrank!{T}(m::Integer, n::Integer, k::Integer, table::Table{T})::IndexedLambda

Calculate the `k`-th De Bruijn term of binary size `n`, with at most `m` free variables,
using tabulated values for Sₙₘ.

This function should be used for repeated unrankings, so that the series Sₙₘ does
not have to be recomputed every time.
"""
function unrank!{T<:Integer}(m::Integer, n::Integer, k::Integer, table::Table{T})::IndexedLambda
    @assert(m >= 0)
    @assert(n >= 0)
    @assert(k >= 1)

    t = tromp!(m, n, table)
    @assert(t >= k)
    
    if m >= n - 1 && k == t
        return IVar(n - 1)
    elseif k <= tromp!(m + 1, n - 2, table)
        return IAbs(unrank!(m + 1, n - 2, k, table))
    else
        return unrank_app!(m, n - 2, 0, k - tromp!(m + 1, n - 2, table), table)
    end
end


function unrank_app!{T<:Integer}(m::Integer, n::Integer, j::Integer, r::Integer,
                                 table::Table{T})::IndexedLambda
    tmnj = tromp!(m, n - j, table)
    tmjtmnj = tromp!(m, j, table) * tmnj

    if r <= tmjtmnj
        dv, rm = divrem(r - 1, tmnj)
        return IApp(unrank!(m, j, dv + 1, table), unrank!(m, n - j, rm + 1, table))
    else
        return unrank_app!(m, n, j + 1, r - tmjtmnj, table)
    end
end


#################
# ITERATING TERMS
#################

"""
    terms{T<:Integer}(m::Integer, n::Integer[, ::Type{T}])

An iterator for all de Bruijn terms of size `n` with at most `m` free variables.
"""
function terms{T<:Integer}(m::Integer, n::Integer, ::Type{T} = Int)
    @assert(m >= 0)
    @assert(n >= 0)

    table = Table{T}()
    tromp!(m, n, table)
    TermsIterator{T}(m, n, table)
end


immutable TermsIterator{T<:Integer}
    m::Integer
    n::Integer
    table::Table{T}
end

typealias TermsIteratorState Int

Base.start{T}(t::TermsIterator{T}) = TermsIteratorState(1)
Base.next{T}(t::TermsIterator{T}, state::TermsIteratorState) =
    (unrank!(t.m, t.n, state, t.table), state + 1)
Base.done{T}(t::TermsIterator{T}, state::TermsIteratorState) =
    state > t.table[(t.m, t.n)]

Base.iteratorsize{T}(::Type{TermsIterator{T}}) = Base.HasLength()
Base.length{T}(t::TermsIterator{T}) = t.table[(t.m, t.n)]
Base.iteratoreltype{T}(::Type{TermsIterator{T}}) = Base.HasEltype()
Base.eltype{T}(::Type{TermsIterator{T}}) = IndexedLambda
