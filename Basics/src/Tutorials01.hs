module Tutorials01 where
import Data.Function
-- # List Comprehensions
--
-- 1. **Pythagorean Triples**
--    Write a function `pythagoreanTriples :: Int -> [(Int, Int, Int)]` 
--    that returns all triples `(a, b, c)` satisfying:
--    - `1 ≤ a < b < c ≤ n`
--    - `a² + b² == c²`
--    Use list comprehensions to generate the result.
--
pythagoreanTriples :: Int -> [(Int, Int, Int)]
-- pythagoreanTriples 0 = []
-- pythagoreanTriples n = undefined  
pythagoreanTriples n = [(a,b,c) | c <- [1..n], b <- [1..c-1], a <- [1..b-1], a^2 + b^2 == c^2 ]

-- 2. **Pairs of Numbers Whose Sum is Prime**
--    Write a function `primeSumPairs :: [Int] -> [(Int, Int)]` that takes 
--    a list of integers and returns all unique pairs `(x, y)` (assuming `x < y`) 
--    for which the sum `x + y` is a prime number.

isPrime :: Int -> Bool
isPrime n 
 | n <= 0 = False
 | n == 1 = False
 | n == 2 = True
 | even n = False
 | otherwise = all (/= 0) [ n `mod` i | i <- [2..s]] --  n is not div by i
  where 
    s = n & fromIntegral & sqrt & floor 

primeSumPairs :: [Int] -> [(Int, Int)]
primeSumPairs [] = []
primeSumPairs (x:xs) = [ (x , y) | y <- xs, isPrime (x+y), x < y ] ++ primeSumPairs xs

--
-- 3. **Extracting Substrings**
--    Write a function `substrings :: String -> [String]` that returns a 
--    list of all non-empty substrings of a given string. 
--    For example, for the string `"abc"` the result should contain 
--    `"a"`, `"ab"`, `"abc"`, `"b"`, `"bc"`, and `"c"`. Use list comprehensions to generate all substrings.
--
-- 4. **Divisor Pairs**
--    Write a function `divisorPairs :: [Int] -> [(Int, Int)]` that takes 
--    a list of integers and returns all distinct pairs `(x, y)` (assuming `x ≠ y`) 
--    for which `x` divides `y` evenly (i.e. `y mod x == 0`).
--
-- 5. **Combinations**
--    Write a function
--    ```haskell
--    combinations :: Int -> [a] -> [[a]]
--    ```
--    that generates all k-element combinations from a given list.
--    For example, for `k = 2` and list `[1,2,3]` the result should be `[[1,2], [1,3], [2,3]]`.

combinations :: Int -> [a] -> [[a]]
combinations 0 _ = [[]] 
combinations _ [] = []
combinations k (x:xs) = [ x:t | t <- combinations (k-1) xs ] ++ k `combinations` xs 
-- # Lazy/Eager Evaluation, `seq`, and Bang Patterns
--
-- 6. **Strict Sum Using `seq`**
--    Write a function `strictSum :: [Int] -> Int` that computes the sum of a list of integers, 
--    using `seq` to force evaluation of the accumulator at each step. 
--    Compare its behaviour with a naive, lazy summation implementation.

lazySum :: [Int] ->Int
lazySum [] = 0
lazySum (x:xs) = x + lazySum xs

okishSum list = go list 0
  where 
   go [] n = n 
   go (x:xs) n = go xs (x+n)

seqSum list = go list 0
  where 
   go [] n = n 
   go (x:xs) n = let acc = x+n in seq acc (go xs acc)

bangSum list = go list 0
  where 
   go [] n = n 
   go (x:xs) !n = go xs (x+n)



-- 7. **Recursive Factorial with Bang Patterns**
--    Write a recursive function `factorial :: Int -> Int` that computes the factorial of a number. 
--    Use bang patterns on the accumulator.
--
-- 8. **Forcing Evaluation of Tuple Components**
--    Write a function `forceTuple :: (Int, Int) -> Int` that takes a pair of integers, 
--    forces evaluation of both components using `seq`, and then returns their sum. 
--    Explain why forcing evaluation can be necessary in some situations.
--
-- 9. **Fibonacci Numbers: `seq` vs. Bang Patterns**
--    Implement two versions of a Fibonacci number generator:
--    - The first version uses `seq` to force evaluation in a helper function.
--    - The second version uses bang patterns on the arguments of the helper function.
