__precompile__()
# ----------------------------------------------------------------------------
module Tutorial
#=
    see also:
        - the walkthrough at http://vladium.com/tutorials/study_julia_with_me/type_annotations/
=#
# ............................................................................

import InteractiveUtils

function subtypetree(T, depth = 0)
    println('\t' ^ depth, T)
    for t in InteractiveUtils.subtypes(T)
        subtypetree(t, depth + 1)
    end
end

function showfields(T ::Type)
    for i in 1 : fieldcount(T)
        println(fieldoffset(T, i), '\t', fieldname(T, i), "\t::", fieldtype(T, i))
    end
end

# ............................................................................

function bar(x ::Float64) ::Float32
    sin(2π * x)
end

function bar_clipped(x ::Float64)
    x < 0.0 ? 0 : sin(2π * x)
end

function sqrt_or_nothing(x ::Float64) ::Union{Float64, Nothing}
    x < 0.0 ? nothing : √x
end

# ............................................................................

function to_JSON(io ::IO, obj)
    visit(obj, io)
end

function visit(obj, io ::IO)
    error("default visit() called for obj type: ", typeof(obj))
end

function visit(obj ::Real, io ::IO)
    print(io, obj)
end

# note that this is redundant given the 'Real' overload above:
#
# function visit(obj ::Bool, io ::IO)
#     write(io, (obj ? "true" : "false"))
# end

function visit(obj ::AbstractString, io ::IO)
    print(io, '\"')
    print(io, obj)
    print(io, '\"')

end

function visit(obj ::AbstractArray, io ::IO)
    print(io, '[')
    for i in 1 : length(obj)
        i > 1 && print(io, ", ")
        visit(obj[i], io)
    end
    print(io, ']')
end

function visit(obj ::AbstractDict, io ::IO)
    print(io, '{')
    first = true
    for (k, v) in obj
        first ? first = false : print(io, ", ")
        visit(k ::AbstractString, io) # assert that key is a string
        print(io, " : ")
        visit(v, io)
    end
    print(io, '}')
end

# adding this overload to support tuples:

function visit(obj ::Tuple, io ::IO)
    print(io, '[')
    for i in 1 : length(obj)
        i > 1 && print(io, ", ")
        visit(obj[i], io)
    end
    print(io, ']')
end

end # of module
# ----------------------------------------------------------------------------
