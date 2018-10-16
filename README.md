[![Build Status](https://travis-ci.org/phipsgabler/BinaryLambdaCalculus.jl.svg?branch=master)](https://travis-ci.org/phipsgabler/BinaryLambdaCalculus.jl)

# BinaryLambdaCalculus.jl #

I wrote this package to play around with the [Binary Lambda
Calculus](https://en.wikipedia.org/wiki/Binary_lambda_calculus) (originally
[defined](http://drops.dagstuhl.de/opus/volltexte/2006/628/pdf/06051.TrompJohn.Paper.628.pdf) by
John Tromp).  During working on that, I separated out the representation of terms into the package
[LambdaCalculus.jl](https://github.com/phipsgabler/LambdaCalculus.jl), which now is a dependency
here.

The basic feature of the binary calculus is that it is just prefix-free encoding of terms in De
Bruijn form:

```
julia> pair = LambdaCalculus.DeBruijn.@lambda f -> f(one, two)
(λ.((1 3) 2))

julia> encode(pair)
"\0\0\0\x01\0\x01\x01\0\x01\x01\x01\0\x01\x01\0"

julia> encode(pair) |> decode
(λ.((1 3) 2))
```

## Combinatorics ##

In addition to that, I reimplemented the counting and unranking functions from [“Counting and
Generating Terms in the Binary Lambda Calculus](https://arxiv.org/pdf/1511.05334v1.pdf) by Grygiel
and Lescanne, which allow one, for example, to enumerate all lambda terms of a certain (binary)
size:

```
julia> collect(terms(0, 10))
6-element Array{LambdaCalculus.DeBruijn.Term,1}:
 (λ.(λ.(λ.(λ.1))))
 (λ.(λ.(λ.3)))
 (λ.(λ.(1 1)))
 (λ.(1 (λ.1)))
 (λ.((λ.1) 1))
 ((λ.1) (λ.1)) 
 
julia> grygiel_lescanne(0, 20)
883
 
julia> grygiel_lescanne(0, 20) == length(collect(terms(0, 20)))
true
```

(And `terms` is an iterator, of course.)


## Installation

```
Pkg.add("git@github.com:phipsgabler/BinaryLambdaCalculus.jl.git")
```

## License ##

This work is licensed under an [MIT license](https://opensource.org/licenses/MIT).
