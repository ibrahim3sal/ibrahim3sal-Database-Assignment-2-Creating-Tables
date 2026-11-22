public class Solution
{
    // 5.1 - Two auxiliary arrays (prefix[] and suffix[])
    // Time Complexity: O(n) — three linear passes over an array of length n.
    // Space Complexity: O(n) — allocates prefix[], suffix[], and answer[] of size n.
    public int[] ProductExceptSelf_PrefixSuffixArrays(int[] nums)
    {
        int n = nums.Length;
        int[] prefix = new int[n];
        int[] suffix = new int[n];
        int[] answer = new int[n];

        prefix[0] = 1;
        for (int i = 1; i < n; i++)
        {
            prefix[i] = prefix[i - 1] * nums[i - 1];
        }

        suffix[n - 1] = 1;
        for (int i = n - 2; i >= 0; i--)
        {
            suffix[i] = suffix[i + 1] * nums[i + 1];
        }

        for (int i = 0; i < n; i++)
        {
            answer[i] = prefix[i] * suffix[i];
        }

        return answer;
    }

    // 5.2 - Space-optimized approach using output array + running variables
    // Time Complexity: O(n) — two linear passes over an array of length n.
    // Space Complexity: O(1) extra space (excluding the output array answer[]).
    public int[] ProductExceptSelf(int[] nums)
    {
        int n = nums.Length;
        int[] answer = new int[n];

        int prefixProduct = 1;
        for (int i = 0; i < n; i++)
        {
            answer[i] = prefixProduct;
            prefixProduct *= nums[i];
        }

        int suffixProduct = 1;
        for (int i = n - 1; i >= 0; i--)
        {
            answer[i] *= suffixProduct;
            suffixProduct *= nums[i];
        }

        return answer;
    }
}