using PEG

export encode, decode


encode(var::IVar)::String = "\x01" ^ var.index * "\x00"
encode(abs::IAbs)::String = "\x00\x00" * encode(abs.body)
encode(app::IApp)::String = "\x00\x01" * encode(app.car) * encode(app.cdr)


@rule term = var | abs | app
@rule var = "\x01"[+] & "\x00" >>> ((i, _) -> IVar(length(i)))
@rule abs = "\x00\x00" & term >>> ((_, y) -> IAbs(y))
@rule app = "\x00\x01" & term & term >>> ((_, car, cdr) -> IApp(car, cdr))


"""
    decode(input::AbstractString)

Parse a De Bruijn indexed term from its binary representation.
"""
function decode(input::AbstractString; onerror = throw)
    try
        parse_whole(term, input)
    catch parser_error
        onerror(parser_error)
    end
end
