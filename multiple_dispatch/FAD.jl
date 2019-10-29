__precompile__()
# ----------------------------------------------------------------------------
module FAD # Forward Automatic Differentiation demo
#=
    see also:
        - the walkthrough at http://vladium.com/tutorials/study_julia_with_me/multiple_dispatch/

    working with this module from REPL:

    julia>include("<path>/FAD.jl")
    julia>using Main.FAD
    ... REPL can now use derivative(), ∂(), root_solve(), etc ...
=#
# ............................................................................

import Base; # needed in order to add base ops overloads

export derivative, ∂, myerf, root_solve; # for convenience of 'using Main.FAD' in REPL

# ............................................................................

struct Context <: Number
    v   ::Float64
    ∂   ::Float64
end
# ............................................................................
# binary ops:

# note: ':()' is necessary to reference certain functions with single-character names

Base.:(+)(lhs ::Context, rhs ::Context) = Context(lhs.v + rhs.v, lhs.∂ + rhs.∂)
Base.:(-)(lhs ::Context, rhs ::Context) = Context(lhs.v - rhs.v, lhs.∂ - rhs.∂)

Base.:(*)(lhs ::Context, rhs ::Context) = Context(lhs.v * rhs.v, lhs.v * rhs.∂ + lhs.∂ * rhs.v)
Base.:(/)(lhs ::Context, rhs ::Context) = Context(lhs.v / rhs.v, (lhs.∂ * rhs.v - lhs.v * rhs.∂) / rhs.v^2)

# unary ops:

Base.:(+)(x ::Context) = x
Base.:(-)(x ::Context) = Context(- x.v, - x.∂)

# math ops:

Base.sin(d ::Context) = Context(sin(d.v),   cos(d.v) * d.∂)
Base.cos(d ::Context) = Context(cos(d.v), - sin(d.v) * d.∂)
# ... add more as needed for your own functions ...

# ............................................................................
# conversion/promotion:

Base.promote_rule(::Type{Context}, ::Type{<: Number}) = Context
Base.convert(::Type{Context}, x ::Real) = Context(x, 0.0)

# ............................................................................
"""
    Given a function 'f' of one variable, return its derivative with respect to that variable.
"""
function derivative(f ::Function)
    return x ::Number -> f(Context(x, 1.0)).∂ # discard value, return derivative
end

∂ = derivative # add a nice-looking alias

# ............................................................................

# to get "official" erf(x), do
# pkg> add SpecialFunctions
# julia> using SpecialFunctions

function myerf(x ::Number)
    Σ = 0.0
    x² = x * x
    for k in 0 : 20 # hardcoding the number of summation terms for simplicity
        Σ += x / (factorial(k) * (2k + 1))
        x *= -x²
    end
    return 2.0 / √π * Σ
end
# ............................................................................
"""
    Newton's method for finding root(s) of 'f'
"""
function root_solve(f ::Function, x₀ ::Number; ϵ = 1e-8)
    i = 1
    while true
        ctx = f(Context(x₀, 1.0))
        println("[$i]: f($x₀)\t= $(ctx.v)")
        abs(ctx.v) < ϵ && break
        x₀ -= ctx.v / ctx.∂ # ignoring issues with division by small floats, etc for simplicity
        i += 1
    end
    return x₀
end

end # of module
# ----------------------------------------------------------------------------
