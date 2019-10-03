__precompile__()
# ----------------------------------------------------------------------------
module Knapsack
#=
    see also:
        - the walkthrough at http://vladium.com/tutorials/study_julia_with_me/knapsack_benchmark/
        - https://en.wikipedia.org/wiki/Knapsack_problem#0/1_knapsack_problem

    running this benchmark from command line:

    >julia knapsack.jl
=#
# ............................................................................
"""
    we need a couple of integers to describe a knapsack item, its value and weight.
    a tuple would work, but a struct makes for more readable code
"""
struct Item
    value   ::Int64; # actually, being so type-specific is not necessary in Julia
    weight  ::Int64;
end
# ............................................................................
"""
    first version of the knapsack solver; uses a full matrix for V and will
    not scale to large problems
"""
function opt_value_BAD(W ::Int64, items ::Array{Item}) ::Int64
    n = length(items)

    # V[w,j] stores opt value achievable with capacity 'w' and using items '1..j':

    V = Array{Int64}(undef, W, n) # Wxn matrix with uninitialized storage

    # initialize first column v[:, 1] to trivial single-item solutions:
    # (note "broadcast assignment" syntax)

    V[:, 1] .= 0
    V[items[1].weight:end, 1] .= items[1].value

    # do a pass through remaining columns:

    for j in 2 : n
        itemⱼ = items[j]
        for w in 1 : W
            V_without_itemⱼ = V[w, j - 1]
            V_allow_itemⱼ = (w < itemⱼ.weight
                ? V_without_itemⱼ
                : (itemⱼ.value + (w ≠ itemⱼ.weight ? V[w - itemⱼ.weight, j - 1] : 0)))
            V[w, j] = max(V_allow_itemⱼ, V_without_itemⱼ)
        end
    end

    return V[W, n]
end
# ............................................................................
"""
    second version of the knapsack solver; uses two column buffers for V
"""
function opt_value(W ::Int64, items ::Array{Item}) ::Int64
    n = length(items)

    # V[w] stores opt value achievable with capacity 'w' and using items '1..j':

    V = zeros(Int64, W) # single column of size W, zero-initialized
    V_prev = Array{Int64}(undef, W) # single column of size W, uninitialized storage

    # initialize 'v' to trivial single-item solutions:
    # (note "broadcast assignment" syntax)

    V[items[1].weight:end] .= items[1].value

    # do a pass through remaining columns:

    for j in 2 : n
        V, V_prev = V_prev, V
        itemⱼ = items[j]
        for w in 1 : W
            V_without_itemⱼ = V_prev[w]
            V_allow_itemⱼ = (w < itemⱼ.weight
                ? V_without_itemⱼ
                : (itemⱼ.value + (w ≠ itemⱼ.weight ? V_prev[w - itemⱼ.weight] : 0)))
            V[w] = max(V_allow_itemⱼ, V_without_itemⱼ)
        end
    end

    return V[W]
end
# ............................................................................
"""
    a simple but good quality [xorshift RNG](https://en.wikipedia.org/wiki/Xorshift)
    that can be ported to all benchmark languages to ensure equivalent test problem
    instances across all ports
"""
function xorshift_rand(seed)
    @assert seed ≠ 0
    x ::UInt64 = seed # want unsigned bit arithmetic

    return function _next()
        x ⊻= (x << 13) # note that python would need 'nonlocal' here
        x ⊻= (x >>> 7)
        x ⊻= (x << 17)
        return x
    end
end

Problem = Tuple{Int64, Array{Item}} # use a type alias for less typing 

"""
    generate a randomized knapsack problem definition of scale 'W'
"""
function make_random_data(W ::Int64, seed ::Int64) ::Problem
    @assert W > 1000 # don't test on very small problems
    n = W ÷ 100
    rng = xorshift_rand(seed)

    items = Array{Item}(undef, n)
    for i in 1 : n
        v = rng() % 1000
        w = 1 + rng() % 2W
        items[i] = Item(v, w)
    end

    return W, items
end
# ............................................................................
"""
    you can use this function to load any knapsack problem defition from a file
    instead of using make_random_data();
    the format is:

     1. first line: <W>
     2. n subsequent lines: <value> <weight> (separated by spaces)
"""
function load_data(in_file ::String) ::Problem
    W = -1
    items = Item[]
    open(in_file) do fd
        for line in eachline(fd)
            line = strip(line)
            if isempty(line)
                break
            end
            if W < 0 # reading first line
                W = parse(Int, line)
            else # reading items
                tokens = split(line)
                @assert length(tokens) == 2
                item = Item(parse(Int, tokens[1]), parse(Int, tokens[2]))

                push!(items, item)
            end
        end
    end

    return W, items
end
# ............................................................................

function run(repeats = 5)
    @assert repeats > 1

    times = zeros(Float64, repeats)
    seed = 12345

    for W in [5_000, 10_000, 20_000, 40_000, 80_000]
        for repeat in 1 : repeats
            W, items = make_random_data(W, seed += 1)
            times[repeat] = @elapsed V = opt_value(W, items)
            # println("V = $(V), time = $(times[repeat])")
        end
        sort!(times)
        println("julia, ", W, ", ", times[(repeats + 1) ÷ 2]) # report W and median time
    end
end

# comment this out if you don't want to run the benchmark on module load:

run()

end # of module
# ----------------------------------------------------------------------------
