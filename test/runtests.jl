using BinaryLambdaCalculus
using Base.Test


# MACROS
let
    local id_x = @indexed_term x -> x
    local id_n = @named_term x -> x

    local id_x_result = @indexed_term a -> (x -> x)(a)
    local id_xx = @indexed_term a -> $id_x(a)
    local id_xn = @indexed_term a -> $id_n(a)

    local id_n_result = @named_term a -> (x -> x)(a)
    local id_nn = @named_term a -> $id_n(a)
    local id_nx = @named_term a -> $id_x(a)
    
    @test alpha_equivalent(id_xx, id_x_result)
    @test alpha_equivalent(id_xn, id_x_result)
    @test alpha_equivalent(id_nn, id_n_result)
    @test alpha_equivalent(id_nx, id_n_result)
end


# ENCODING & CONVERSION
let
    local id = @named_term x -> x
    local Ω = @named_term (x -> x(x))(x -> x(x))
    local K = @named_term x -> y -> x
    local free = @named_term x -> y
    local named_terms = [id, Ω, K, free]

    local id_ix = @indexed_term x -> x
    local Ω_ix = @indexed_term (x -> x(x))(x -> x(x))
    local K_ix = @indexed_term x -> y -> x
    local free_ix = @indexed_term x -> y
    local indexed_terms = [id_ix, Ω_ix, K_ix, free_ix]
    
    for t in named_terms
        @test alpha_equivalent(fromdebruijn(todebruijn(t)), t)
        @test fromdebruijn(todebruijn(t), [:x, :y, :z]) == t
    end

    for t in indexed_terms
        @test todebruijn(fromdebruijn(t)) == t
        @test alpha_equivalent(decode(encode(t)), t)
    end

    for (tn, tx) in zip(named_terms, indexed_terms)
        @test alpha_equivalent(todebruijn(tn), tx)
        @test alpha_equivalent(tn, fromdebruijn(tx))
    end
end


# EVALUATION
let
    local terms = [@indexed_term((x -> (x -> x))(z -> z)),
                   @indexed_term((x -> x)(z -> (x -> x)(z))),
                   @indexed_term((f -> x -> f(f(x)))(f -> x -> f(f(x))))]
    local results = [@indexed_term(x -> x),
                     @indexed_term(z -> z),
                     @indexed_term(x -> y -> x(x(x(x(y)))))]
    
    for (t, r) in zip(terms, results)
        @test alpha_equivalent(evaluate(t), r)
    end
end


# ENUMERATION
function S{T}(m::T, n::T)
    # explicit recursive formula for testing
    if n <= 1
        return 0
    else
        return T(m >= n - 1) + S(m + 1, n - 2) + sum(S(m, k) * S(m, n - 2 - k) for k = 0:(n-2))
    end
end

let
    local S₀ₙ = [0, 0, 0, 0, 1, 0, 1, 1, 2, 1, 6, 5, 13, 14, 37, 44, 101, 134, 298, 431]
    @test all(S₀ₙ[i+1] == S(0, i) for i = 0:19) # ensure the reference is correct...
    @test [tromp(0, n) for n = 0:19] == S₀ₙ

    for m = 1:3, n = 0:20
        @test tromp(m, n) == S(m, n)
        @test length(terms(m, n)) == S(m, n)
    end

    let m = 3, n = 100,
        s = (a, b) -> tromp(a, b, BigInt)
        @test s(m, n) == s(m + 1, n - 2) + sum(s(m, k) * s(m, n - 2 - k) for k = 0:(n-2))
    end
end
