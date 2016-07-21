# OUTER INTERFACE
function tromp(m::Integer, n::Integer, T::Type = Int)
    return tromptable(m, n, T)[n+1, m+1]
end

function unrank(m::Integer, n::Integer, k::Integer, T::Type = Int)
    @assert(m >= 0)
    @assert(n >= 0)
    @assert(k >= 0)

    unrank_with(m, n, k, tromptable(m, n, T))
end


# INTERNAL FUNCTIONS

# this is a needed patch to be able to use, eg, UInt
import Lazy.getindex
getindex(l::Lazy.List, i::Integer) = i <= 1 ? first(l) : tail(l)[i-1]

# the dynamic programming version of the recursive algorithm
function tromptable(m::Integer, n::Integer, T::Type = Int)
    @assert(m >= 0)
    @assert(n >= 0)

    values = zeros(T, n+1, (n÷2)+2)
    
    for i = 2:n, j = 0:(n÷2)
        ti = values[1:(i-1), j+1]
        s = dot(ti, reverse(ti))
        values[i+1, j+1] = T(i-2 < j) + values[i-1, j+2] + s
    end
    
    return values
end

function unrank_with{T <: Integer}(m::Integer, n::Integer, k::Integer, table::Array{T, 2})
    if m >= n-1 && k == table[n+1, m+1]
        return IVar(n-1)
    elseif k <= table[n-1, m+2]
        return IAbs(unrank_with(m+1, n-2, k, table))
    else
        function unrankApp(n, j, h)
            tmnj = table[n-j+1, m+1]
            tmjtmnj = table[j+1, m+1] * tmnj

            if h <= tmjtmnj
                dv, rm = divrem(h-1, tmnj)
                return IApp(unrank_with(m, j, dv+1, table), unrank_with(m, n-j, rm+1, table))
            else
                return unrankApp(n, j+1, h-tmjtmnj)
            end
        end

        return unrankApp(n-2, 0, k-table[n-1, m+2])
    end
end


# ITERATOR FOR TERMS

terms(m::Integer, n::Integer, T::Type = Int) =
    TermsIterator{T}(m, n, tromptable(m, n, T))


immutable TermsIterator{T <: Integer}
    m :: T
    n :: T
    table :: Array{T, 2}
end

immutable TermsIteratorState{T <: Integer}
    k :: T
end

@inline increment{T <: Integer}(s::TermsIteratorState{T}) =
    TermsIteratorState{T}(s.k + 1)

Base.start{T <: Integer}(t::TermsIterator{T}) =
    TermsIteratorState{T}(1)
Base.next{T <: Integer}(t::TermsIterator{T}, state::TermsIteratorState{T}) =
    (unrank_with(t.m, t.n, state.k, t.table), increment(state))
Base.done{T <: Integer}(t::TermsIterator{T}, state::TermsIteratorState{T}) =
    state.k > t.table[t.n+1, t.m+1]
Base.length{T <: Integer}(t::TermsIterator{T}) =
    t.table[t.n+1, t.m+1]
Base.eltype{T <: Integer}(::Type{TermsIterator{T}}) = T
