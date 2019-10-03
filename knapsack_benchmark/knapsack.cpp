
#if __cplusplus < 201400L
#   error "need c++14 or later"
#endif

#define NDEBUG

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <iostream>
#include <memory>
#include <tuple>
#include <vector>

//----------------------------------------------------------------------------
/*
    this is an almost one-for-one translation of the Julia version, see knapsack.jl
    for more comments.

    running this benchmark from command line:

    >g++ -O3 -Wall -o knapsack knapsack.cpp
    >./knapsack
*/
namespace knapsack
{
using std::int64_t;
using std::uint64_t;

//............................................................................

struct item
{
    int64_t const value;
    int64_t const weight;

}; // end of class
//............................................................................

int64_t
opt_value (int64_t const W, std::vector<item> const & items)
{
    auto const n = items.size ();

    std::unique_ptr<int64_t []> const v_data { std::make_unique<int64_t []> (W) }; // "zeros"
    std::unique_ptr<int64_t []> const v_prev_data { std::make_unique<int64_t []> (W) }; // "zeros"

    int64_t * V { v_data.get () };
    int64_t * V_prev { v_prev_data.get () };

    for (int64_t w = items[0].weight; w <= W; ++ w)
        V[w - 1] = items[0].value;

    for (std::size_t j = 1; j < n; ++ j)
    {
        std::swap (V, V_prev);
        item const & item { items [j] };

        for (int64_t w = 1; w <= W; ++ w)
        {
            auto const V_without_item_j = V_prev[w - 1];
            auto const V_allow_item_j = (w < item.weight
                ? V_without_item_j
                : (item.value + (w != item.weight ? V_prev[w - 1 - item.weight] : 0)));

            V[w - 1] = std::max(V_allow_item_j, V_without_item_j);
         }
    }

    return V[W - 1];
}
//............................................................................

uint64_t
next_rand (uint64_t & x) // note: 'x' maintains RNG state
{
    x ^= (x << 13);
    x ^= (x >> 7);
    x ^= (x << 17);

    return x;
}

using problem   = std::tuple<int64_t, std::vector<item>>;

problem
make_random_data (int64_t const W, int64_t const seed)
{
    int64_t const n = W / 100;
    uint64_t rng = seed;

    std::vector<item> items { };
    for (int64_t i = 0; i < n; ++ i)
    {
        int64_t const v = next_rand(rng) % 1000;
        int64_t const w = 1 + next_rand(rng) % (2 * W);

        items.emplace_back (item {v, w});
    }

    return std::make_tuple (W, std::move(items));
}
//............................................................................

void
run (int32_t const repeats = 5)
{
    std::vector<double> times(repeats);
    int64_t seed = 12345;

    for (int64_t W : { 5'000, 10'000, 20'000, 40'000, 80'000 })
    {
        for (int32_t repeat = 0; repeat < repeats; ++ repeat)
        {
            auto spec = make_random_data(W, seed += 1);
            auto start = std::chrono::high_resolution_clock::now();

            opt_value(std::get<0>(spec), std::get<1>(spec));

            auto stop = std::chrono::high_resolution_clock::now();

            times[repeat] = std::chrono::duration<double>(stop - start).count();
//            std::cout << "V = " << V << ", time = " << times[repeat] << std::endl;
        }

        std::sort (times.begin(), times.end());
        std::cout << "c++, " << W << ", " << times[repeats / 2] << std::endl;
    }
}

} // end of 'knapsack'
//----------------------------------------------------------------------------

int main()
{
    knapsack::run ();

	return 0;
}
//----------------------------------------------------------------------------
