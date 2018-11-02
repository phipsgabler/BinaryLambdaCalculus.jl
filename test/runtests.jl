using BinaryLambdaCalculus
using Test

@testset "Encoding/decoding" begin
    for t in terms(0, 10)
        @test decode(encode(t)) == t
        @test decompress(compress(t)) == t
    end
end

@testset "Enumeration" begin
    function S(m::T, n::T) where T
        # explicit recursive formula for testing
        if n <= 1
            return 0
        else
            return T(m >= n - 1) + S(m + 1, n - 2) + sum(S(m, k) * S(m, n - 2 - k) for k = 0:(n-2))
        end
    end

    S₀ₙ = [0, 0, 0, 0, 1, 0, 1, 1, 2, 1, 6, 5, 13, 14, 37, 44, 101, 134, 298, 431]
    @test all(S₀ₙ[i+1] == S(0, i) for i = 0:19) # ensure the reference is correct...
    @test [grygiel_lescanne(0, n) for n = 0:19] == S₀ₙ

    for m = 1:3, n = 0:20
        @test grygiel_lescanne(m, n) == S(m, n)
        @test length(terms(m, n)) == S(m, n)
    end

    let m = 3, n = 100,
        s = (a, b) -> grygiel_lescanne(a, b, BigInt)
        @test s(m, n) == s(m + 1, n - 2) + sum(s(m, k) * s(m, n - 2 - k) for k = 0:(n-2))
    end
end
