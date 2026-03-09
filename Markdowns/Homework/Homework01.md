# Homework 01

## List Comprehensions

1. **Goldbach Pairs**
   Write a function `goldbachPairs :: Int -> [(Int, Int)]` that, given an even integer `n ≥ 4`, returns all pairs `(p, q)` satisfying:
   - `p` and `q` are both prime numbers
   - `p + q == n`
   - `p ≤ q`

   Use a list comprehension to generate the result. Define a helper `isPrime :: Int -> Bool` using Exercise 3.

2. **Coprime Pairs**
   Write a function `coprimePairs :: [Int] -> [(Int, Int)]` that takes a list of positive integers and returns all unique pairs `(x, y)` (with `x < y`) for which `gcd x y == 1`. You may use Haskell's built-in `gcd`.

3. **Sieve of Eratosthenes**
   The *Sieve of Eratosthenes* is an ancient algorithm for finding all primes up to a given limit. It works as follows: starting from the list `[2..n]`, take the first element `p` — it must be prime — then remove all multiples of `p` from the rest of the list and repeat.

   Implement this as a recursive function `sieve :: [Int] -> [Int]`, where each recursive step uses a list comprehension to filter out multiples of the head. Then define:
   ```haskell
   primesTo :: Int -> [Int]
   primesTo n = sieve [2..n]
   ```
   Finally, use `primesTo` to define `isPrime :: Int -> Bool` that checks whether a given positive integer is prime.

4. **Matrix Multiplication**
   Represent a matrix as `[[Int]]` (a list of rows). Write
   ```haskell
   matMul :: [[Int]] -> [[Int]] -> [[Int]]
   ```
   using nested list comprehensions. If the first matrix has dimensions `m × p` and the second `p × n`, then the entry at row `i`, column `j` of the product is:
   ```
   sum [ a !! i !! k * b !! k !! j | k <- [0 .. p-1] ]
   ```
   The outer comprehension should range over row indices `i` and column indices `j`.

5. **Permutations**
   Write a function
   ```haskell
   permutations :: Int -> [a] -> [[a]]
   ```
   that generates all k-element permutations (ordered selections without repetition) from a given list.
   For example, for `k = 2` and list `[1,2,3]` the result should be `[[1,2],[1,3],[2,1],[2,3],[3,1],[3,2]]`.

## Lazy/Eager Evaluation, `seq`, and Bang Patterns

6. **Hamming Numbers**
   A *Hamming number* is a positive integer whose only prime factors are 2, 3, and 5 — numbers of the form 2^a × 3^b × 5^c with a, b, c ≥ 0. The sequence begins: 1, 2, 3, 4, 5, 6, 8, 9, 10, 12, …

   (a) Write a helper
   ```haskell
   merge :: Ord a => [a] -> [a] -> [a]
   ```
   that merges two sorted (potentially infinite) lists into one sorted list, eliminating duplicates.

   (b) Using `merge`, define the infinite list
   ```haskell
   hamming :: [Integer]
   ```
   as a single definition. 

7. **Integer Power with Bang Patterns**
   Write a recursive function `power :: Int -> Int -> Int` that computes `power b e = b ^ e` using an accumulator. Use bang patterns on the accumulator to ensure strict evaluation.

8. **Running Maximum: `seq` vs. Bang Patterns**
   Implement two versions of a function `listMax :: [Int] -> Int` that returns the maximum element of a non-empty list using a helper with an accumulator:
   - The first version uses `seq` to force evaluation of the accumulator in the helper function.
   - The second version uses bang patterns on the accumulator argument of the helper function.

9. **Infinite Prime Stream**
   The `primesTo` function from Exercise 3 only generates primes up to a fixed bound. Using lazy evaluation we can instead define an *infinite* stream of all primes.

   (a) Define
   ```haskell
   primes :: [Int]
   ```
   as an infinite list of all prime numbers, by applying the same sieve idea from Exercise 3 to the infinite list `[2..]`. Your `sieve` function should be unchanged — only the input changes.

   (b) Use `primes` to give a new definition of `isPrime :: Int -> Bool` that does not require an explicit upper bound.

10. **Strict Accumulation and Space Leaks**
    Computing the mean of a list requires knowing both the sum and the length. Write a function
    ```haskell
    mean :: [Double] -> Double
    ```
    using a tail-recursive helper. Do *not* use any library functions for the recursion.

    (a) Write a first version with no strictness annotations. 

    (b) Fix the space leak using bang patterns. Is a bang pattern on the pair itself sufficient, or do the components also need to be forced individually?

    (c) Generalise your strict solution to compute both the mean and the *variance* σ² = (Σxᵢ²)/n − μ² in a single pass. 
    Apply bang patterns appropriately to all three components.
