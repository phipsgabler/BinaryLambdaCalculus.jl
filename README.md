[![Build Status](https://travis-ci.org/phipsgabler/BinaryLambdaCalculus.jl.svg?branch=master)](https://travis-ci.org/phipsgabler/BinaryLambdaCalculus.jl)

# BinaryLambdaCalculus.jl #

For examples, see the [examples notebook](./examples.ipynb), but they might be outdated.

## Basics ##

This package implements data structures and functions to play around with the
untyped [lambda calculus](https://en.wikipedia.org/wiki/Lambda_calculus).  For a start, implements
representations of named and De-Bruijn-indexed terms, and their conversions, with some convenience
macros taking Julia lambdas:

```
julia> Ω = @named_term (x -> x(x))(x -> x(x))
((λx.(x x)) (λx.(x x)))

julia> K_ix = @indexed_term x -> y -> x
(λ{x}.(λ{y}.{x:2}))

julia> fromdebruijn(K_ix)
(λx.(λy.x))

```

As you can see, indexed terms try to do their best to rename the original variable names, and will
change or make up names only when neccessary.

Terms can also be spliced into other terms (conversion from and to indexed form happens
automatically):

```
julia> fst = @named_term t -> t($K_ix)
(λt.(t (λx.(λy.x))))
```

Function literals are tried to be translated in meaningful (ie., curried) ways:

```
julia> pair = @named_term f -> f(one, two)
(λf.((f one) two))
```

Finally, we can perform normal order reduction on indexed terms:

```
julia> evaluate(@indexed_term $fst($pair))
{one:1}
```

## Binary Lambda Calculus ##

Originally, I wrote this package to play around with
the [Binary Lambda Calculus](https://en.wikipedia.org/wiki/Binary_lambda_calculus) (originally
defined [here](http://drops.dagstuhl.de/opus/volltexte/2006/628/pdf/06051.TrompJohn.Paper.628.pdf)).
Therefore, there are conversions to and from the binary representation of indexed terms (which is
the "binary" part):

```
julia> pair |> todebruijn |> encode
"\0\0\0\x01\0\x01\x01\0\x01\x01\0\x01\x01\x01\0"

julia> pair |> todebruijn |> encode |> decode
(λ.((1 2) 3))

julia> pair |> todebruijn |> encode |> decode |> fromdebruijn
(λx1.((x1 x2) x3))
```

(Of course, these cannot keep remember the original bindings.)

## Combinatorics ##

Finally, I reimplemented the counting and unranking functions
from [this paper](https://arxiv.org/pdf/1511.05334v1.pdf), which allow one, for example, to
enumerate all lambda terms of a certain (binary) size:

```
julia> collect(terms(0, 10))
6-element Array{BinaryLambdaCalculus.IndexedLambda,1}:
 (λ.(λ.(λ.(λ.1))))
 (λ.(λ.(λ.3)))
 (λ.(λ.(1 1)))
 (λ.(1 (λ.1)))
 (λ.((λ.1) 1))
 ((λ.1) (λ.1))
 
julia> tromp(0, 20)
883
 
julia> tromp(0, 20) == length(collect(terms(0, 20)))
true
```

(`terms` is an iterator, of course.)

## Installation

```
Pkg.clone("git@github.com:phipsgabler/BinaryLambdaCalculus.jl.git")
```

## License ##

This work is licensed under an [MIT license](https://opensource.org/licenses/MIT).
