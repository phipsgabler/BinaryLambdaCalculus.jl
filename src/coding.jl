import LambdaCalculus
using LambdaCalculus.DeBruijn
using PEG

export encode,
    decode,
    compress,
    decompress


encode(var::Var) = "\x01" ^ var.index * "\x00"
encode(abs::Abs) = "\x00\x00" * encode(abs.body)
encode(app::App) = "\x00\x01" * encode(app.car) * encode(app.cdr)


@rule term = var, abs, app
@rule var = "\x01"[+] & "\x00" > ((i, _) -> Var(length(i)))
@rule abs = "\x00\x00" & term > ((_, y) -> Abs(y))
@rule app = "\x00\x01" & term & term > ((_, car, cdr) -> App(car, cdr))


"""
    decode(input::AbstractString)

Parse a De Bruijn indexed term from its binary representation.
"""
function decode(input::AbstractString; onsuccess = identity, onerror = throw)
    try
        onsuccess(parse_whole(term, input))
    catch parser_error
        onerror(parser_error)
    end
end


compress(term::Term) = BitVector([c == '\x01' for c in encode(term)])

function decompress(compressed::BitVector; onsuccess = identity, onerror = throw)
    decode(String(map(Char, compressed)); onsuccess = onsuccess, onerror = onerror)
end
