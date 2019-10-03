
import java.util.Arrays;

//----------------------------------------------------------------------------
/*
	this is an almost one-for-one translation of the Julia version, see knapsack.jl
	for more comments.

	running this benchmark from command line:

	>mkdir bin; javac -d bin Knapsack.java
	>java -cp bin Knapsack
*/
public class Knapsack
{	
	static final class Item
	{
		Item(final long value, final long weight)
		{
			this.value = value;
			this.weight = weight;
		}
		
		final long value;
		final long weight;
		
	} // end of nested class
	//........................................................................
	/*
	 * some types are changed to 'int' in this version because in Java
	 * you can't index into arrays with types wider than 'int'
	 */
	static long optValue(final int W, final Item[] items)
	{
		final int n = items.length;
		
		long[] V = new long [W];
		long[] V_prev = new long [W];
		
	    for (int w = (int)items[0].weight; w <= W; ++ w)
	        V[w - 1] = items[0].value;
	    
	    for (int j = 1; j < n; ++ j)
	    {
	        long[] temp = V; V = V_prev; V_prev = temp;

	        final Item item = items[j];

	        for (int w = 1; w <= W; ++ w)
	        {
	            final long V_without_item_j = V_prev[w - 1];
	            final long V_allow_item_j = (w < item.weight
	                ? V_without_item_j
	                : (item.value + (w != item.weight ? V_prev[w - 1 - (int)item.weight] : 0)));

	            V[w - 1] = Math.max(V_allow_item_j, V_without_item_j);
	         }
	    }
	    
	    return V[W - 1];
	}
	//........................................................................
	
	static final class XorshiftRandom
	{
		XorshiftRandom(final long seed)
		{
			x = seed;
		}
		
		public long next()
		{
			x ^= (x << 13);
			x ^= (x >>> 7);
			x ^= (x << 17);
			
			return x;
		}
		
		private long x;
	}
	//........................................................................
	
	static final class Problem
	{
		Problem (final int W, final Item[] items)
		{
			this.W = W;
			this.items = items;
		}
		
		final int W;
		final Item[] items;
		
	} // end of nested class
	
	static Problem makeRandomData(final int W, final long seed)
	{
		assert W > 1000;
		final int n = W / 100;
		final XorshiftRandom rng = new XorshiftRandom(seed);
		
		final Item[] items = new Item[n];
		
		for (int i = 0; i < n; ++ i)
		{
			final long v = Long.remainderUnsigned(rng.next(), 1000);
			final long w = 1 + Long.remainderUnsigned(rng.next(), 2 * W);
			
//			System.out.println("v = " + v + ", w = " + w);
			items[i] = new Item(v, w);
		}
		
		return new Problem(W, items);
	}
	//........................................................................
	
	static void run(final int repeats)
	{
		final double[] times = new double[repeats];
		long seed = 12345;
		
		final int[] Ws = { 5_000, 10_000, 20_000, 40_000, 80_000 };
		for (int W : Ws)
		{
			for (int repeat = 0; repeat < repeats; ++ repeat)
			{
				final Problem spec = makeRandomData(W, seed += 1);
				final long start = System.nanoTime();
				
				final long V = optValue(spec.W, spec.items);
		
				final long stop = System.nanoTime();
				times[repeat] = (stop - start) / 1e9;
//				System.out.println("W = " + W + ", V = " + V + ", time: " + times[repeat]);
			}
			
			Arrays.sort(times);
			System.out.println("java, " + W + ", " + times[repeats / 2]);
		}
	}
	//........................................................................
	
	public static void main(String[] args)
	{
		run(5);
	}
}
//----------------------------------------------------------------------------
