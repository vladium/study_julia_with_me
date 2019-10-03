
import sys
if sys.hexversion < 0x3000000: raise RuntimeError("expecting python v3+ instead of %x" % sys.hexversion)

import array
import numpy as np
import time

# ----------------------------------------------------------------------------
'''
    this is an almost one-for-one translation of the Julia version, see knapsack.jl
    for more comments.
    
    running this benchmark from command line:
    
    >python3 -O ...knapsack.py
'''

class item(object):
    def __init__(self, value, weight):
        self.value = value
        self.weight = weight
        
    def __repr__(self):
        return "(" + str(self.value) + ", " + str(self.weight) + ")"
# ............................................................................
        
def opt_value(W, items):    
    n = len(items)
    
    V = [0 for i in range(W)]
    V_prev = [0 for i in range(W)]

    # use the next 2 lines to use python "native" arrays instead:
    # (for me, this choice is slower 2x than plain python lists)
    
#     V = array.array('q', [0 for i in range(W)])
#     V_prev = array.array('q', [0 for i in range(W)])

    # use the next 2 lines to use numpy arrays instead:
    # (for me, this choice is nearly 2x slower)

#     V = np.array([0 for i in range(W)], dtype="i8")
#     V_prev = np.array([0 for i in range(W)], dtype="i8")
    
    for w in range(items[0].weight, W + 1):
        V[w - 1] = items[0].value;
        
    for j in range(1, n):
        V, V_prev = V_prev, V
        item_j = items[j]
        for w in range(1, W + 1):
            V_without_item_j = V_prev[w - 1]
            V_allow_item_j = (V_without_item_j if w < item_j.weight
                else (item_j.value + (V_prev[w - 1 - item_j.weight] if w != item_j.weight
                    else 0)))
            
            V[w - 1] = max(V_allow_item_j, V_without_item_j)
            
    return V[W - 1]             
    
# ............................................................................

# some contortions are needed in python to ensure uint64_t arithmetic:

_13 = np.uint64(13)
_7  = np.uint64(7)
_17 = np.uint64(17)

def xorshift_rand(seed):
    assert seed != 0
    x = np.uint64(seed)
    
    def _next():
        nonlocal x
        x ^= (x << _13);
        x ^= (x >> _7);
        x ^= (x << _17);

        return int(x);
    
    return _next

def make_random_data(W, seed):
    assert W > 1000
    n = W // 100
    rng = xorshift_rand(seed)
    
    items = []
    for i in range(n):
        v = rng() % 1000
        w = 1 + rng() % (2 * W)
         
        items.append(item(v, w))
    
    return W, items

# ............................................................................

def run(repeats = 5):
        
    times = [0.0 for i in range(repeats)]
    seed = 12345
    
    for W in [5000, 10000, 20000, 40000, 80000]:
        for repeat in range(repeats):
            seed += 1
            W, items = make_random_data(W, seed)
            start = time.time_ns ()
            
            V = opt_value(W, items)
            
            stop = time.time_ns()
            times[repeat] = (stop - start) / 1e9
#             print("V = %d, time = %f" % (V, times[repeat]))
            
        times.sort()
        print("python, %d, %f" % (W, times[repeats // 2]))

# ............................................................................

if __name__ == '__main__':
    run ()

# ----------------------------------------------------------------------------