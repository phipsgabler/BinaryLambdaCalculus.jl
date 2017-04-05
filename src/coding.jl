encode(var::IVar)::String = "\x1" ^ var.index * "\0"
encode(abs::IAbs)::String = "\0\0" * encode(abs.body)
encode(app::IApp)::String = "\0\x1" * encode(app.car) * encode(app.cdr)


# @grammar blc begin
#     start = term{ _1 }
#     term = var | abs | app 
#     var = (+("\x01") + "\0"){ IVar(length(_1.value)) }
#     abs = ("\0\0" + term){ IAbs(_2) }
#     app = ("\0\x01" + term + term){ IApp(_2, _3) }
# end

# """
# Parse a De Bruijn indexed term from its binary representation.

# Returns a `Nullable{IndexedLambda}`, depending on the success of the parsing.
# On error, the function `onerror` is called on the error value of the parser.
# """
# function decode(bytes::AbstractString, onerror = e -> return)
#     parser_result = parse(blc, bytes)
    
#     if parser_result[3] == nothing
#         return Nullable(parser_result[1])
#     else
#         onerror(parser_result[3])
#         return Nullable{IndexedLambda}()
#     end
# end
