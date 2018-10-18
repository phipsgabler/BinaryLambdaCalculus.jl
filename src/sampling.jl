import Random: AbstractRNG, rand, Sampler

export GeneralTermSampler,
    large_terms,
    BoundedTermSampler

function S∞(z)
    sq = z^6 + 2z^5 - 5z^4 + 4z^3 - z^2 - 2z + 1
    num = z^3 - z^2 - z + 1 - √sq
    den = 2z^2 * (1 - z)
    num / den
end

p₁(x) = x^2 / (1 - x) / S∞(x)
p₂(x) = p₁(x) + x^2

const ρ = 0.509308127024237357194177485
const ρ² = ρ * ρ
const p₁ρ = (1 - ρ²) / 2
const p₂ρ = p₁ρ + ρ²


struct GeneralTermSampler <: Sampler{Term}
    x::Float64
    p₁::Float64
    p₂::Float64
end

GeneralTermSampler(x) = GeneralTermSampler(x, p₁(x), p₂(x))

const large_terms = GeneralTermSampler(ρ, p₁ρ, p₂ρ)


function rand_index(rng::AbstractRNG, s::GeneralTermSampler)
    result = 1
    
    while rand(rng) < s.x
        result += 1
    end

    return result
end

function rand(rng::AbstractRNG, s::GeneralTermSampler)
    p = rand(rng)
    
    if p < s.p₁
        return Var(rand_index(rng, s))
    elseif p < s.p₂
        return Abs(rand(rng, s))
    else
        App(rand(rng, s), rand(rng, s))
    end
end



struct BoundedTermSampler <: Sampler{Term}
    lower::Int
    upper::Int
end

function rand_ceiled(rng::AbstractRNG, s::BoundedTermSampler)::Union{Term, Nothing}
    p = rand(rng)

    if p < p₁ρ
        i = rand_index(rng, large_terms)
        return i < s.upper ? Var(i) : nothing
    elseif p < p₂ρ
        mbt = rand_ceiled(rng, s)
        if mbt !== nothing && length(mbt) + 2 ≤ s.upper
            return Abs(mbt)
        else
            return nothing
        end
    else
        mbt1, mbt2 = rand_ceiled(rng, s), rand_ceiled(rng, s)
        if mbt1 !== nothing && mbt2 !== nothing && length(mbt1) + length(mbt2) + 2 ≤ s.upper
            return App(mbt1, mbt2)
        else
            return nothing
        end
    end
end

function rand(rng::AbstractRNG, s::BoundedTermSampler)
    candidate = rand_ceiled(rng, s)

    while candidate == nothing || length(candidate) < s.lower
        candidate = rand_ceiled(rng, s)
    end

    return candidate
end
