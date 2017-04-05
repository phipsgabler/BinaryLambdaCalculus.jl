# produce an infinite sequence of unique names,
# by appending integers to the given names

immutable NamesGenerator
    names::Array{String}
end

function Base.start(it::NamesGenerator)
    return -1, start(it.names)
end

function Base.next(it::NamesGenerator, state)
    i, s = state
    name, s = next(it.names, s)

    if i >= 0
        newname = Symbol(name * string(i))
    else
        newname = Symbol(name)
    end

    if done(it.names, s)
        i += 1
        s = start(it.names)
    end

    return newname, (i, s)
end

Base.done(it::NamesGenerator, state) = false
Base.iteratorsize(::Type{NamesGenerator}) = Base.IsInfinite()
Base.iteratoreltype(::Type{NamesGenerator}) = Base.HasEltype()
Base.eltype(::Type{NamesGenerator}) = Symbol

generatenames(names::Array{String}) = NamesGenerator(unique(names))

generatenames(tag::String) = (Symbol("$(tag)$(i)") for i in countfrom(0))
