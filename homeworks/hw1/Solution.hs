{-# LANGUAGE BangPatterns #-}

module Solution where

-- Exercise 3: Sieve of Eratosthenes (defined first, used by Exercise 1)

sieve :: [Int] -> [Int]
sieve []     = []
sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]

primesTo :: Int -> [Int]
primesTo n = sieve [2..n]

isPrime :: Int -> Bool
isPrime n = n >= 2 && n `elem` primesTo n

-- Exercise 1: Goldbach Pairs

goldbachPairs :: Int -> [(Int, Int)]
goldbachPairs n = [(p, q) | p <- primesTo n, let q = n - p, p <= q, isPrime q]

-- Exercise 2: Coprime Pairs

coprimePairs :: [Int] -> [(Int, Int)]
coprimePairs xs = [(x, y) | x <- xs, y <- xs, x < y, gcd x y == 1]

-- Exercise 4: Matrix Multiplication

matMul :: [[Int]] -> [[Int]] -> [[Int]]
matMul a b =
  let p = length (head a)
  in [[sum [a !! i !! k * b !! k !! j | k <- [0..p-1]]
      | j <- [0 .. length (head b) - 1]]
     | i <- [0 .. length a - 1]]

-- Exercise 5: Permutations

permutations :: Int -> [a] -> [[a]]
permutations 0 _  = [[]]
permutations _ [] = []
permutations k xs = [xs !! i : rest
                    | i <- [0 .. length xs - 1],
                      rest <- permutations (k - 1) (removeAt i xs)]
  where
    removeAt i ys = take i ys ++ drop (i + 1) ys

-- Exercise 6a: Merge for Hamming numbers

merge :: Ord a => [a] -> [a] -> [a]
merge [] ys = ys
merge xs [] = xs
merge (x:xs) (y:ys)
  | x < y    = x : merge xs (y:ys)
  | x > y    = y : merge (x:xs) ys
  | otherwise = x : merge xs ys

-- Exercise 6b: Hamming numbers

hamming :: [Integer]
hamming = 1 : merge (map (*2) hamming) (merge (map (*3) hamming) (map (*5) hamming))

-- Exercise 7: Integer Power with Bang Patterns

power :: Int -> Int -> Int
power b e = go 1 b e
  where
    go !acc _ 0      = acc
    go !acc base exp = go (acc * base) base (exp - 1)

-- Exercise 8: Running Maximum

-- Version with seq
listMaxSeq :: [Int] -> Int
listMaxSeq (x:xs) = go x xs
  where
    go acc []     = acc
    go acc (y:ys) = let acc' = max acc y
                    in acc' `seq` go acc' ys
listMaxSeq []     = error "empty list"

-- Version with bang patterns
listMaxBang :: [Int] -> Int
listMaxBang (x:xs) = go x xs
  where
    go !acc []     = acc
    go !acc (y:ys) = go (max acc y) ys
listMaxBang []     = error "empty list"

listMax :: [Int] -> Int
listMax = listMaxBang

-- Exercise 9a: Infinite Prime Stream

primes :: [Int]
primes = sieve [2..]

-- Exercise 9b: isPrime using infinite primes
-- (We already defined isPrime above using primesTo; here's the infinite version)

isPrime' :: Int -> Bool
isPrime' n
  | n < 2     = False
  | otherwise  = n `elem` takeWhile (<= n) primes

-- Exercise 10a: Mean (lazy, space leak version)

meanLazy :: [Double] -> Double
meanLazy xs = go 0 0 xs
  where
    go s l []     = s / l
    go s l (y:ys) = go (s + y) (l + 1) ys

-- Exercise 10b: Mean with bang patterns (strict)

meanStrict :: [Double] -> Double
meanStrict xs = go 0 0 xs
  where
    go !s !l []     = s / l
    go !s !l (y:ys) = go (s + y) (l + 1) ys
    -- A bang on a pair alone is NOT sufficient; the components must be forced individually.

-- Exercise 10c: Mean and Variance in a single pass with bang patterns

meanVariance :: [Double] -> (Double, Double)
meanVariance xs = let (s, sq, l) = go 0 0 0 xs
                      mu = s / l
                  in (mu, sq / l - mu * mu)
  where
    go !s !sq !l []     = (s, sq, l)
    go !s !sq !l (y:ys) = go (s + y) (sq + y * y) (l + 1) ys

mean :: [Double] -> Double
mean = meanStrict
