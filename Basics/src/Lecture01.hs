{-# OPTIONS_GHC -Wno-missing-export-lists #-}
module Lecture01 where

-- quicksort algorithm.
-- sorts a list of any orderable type recursively.
-- uses the first element as pivot, splits the rest into smaller and
-- greater-or-equal sublists, sorts each recursively, then concatenates.
--
-- examples:
--   quicksort [3,1,4,1,5,9,2,6] = [1,1,2,3,4,5,6,9]
--   quicksort "haskell"         = "aehklls"
--   quicksort []                = []
--
-- quicksort ::  [Int] -> [Int]
quicksort [] = []
quicksort (x:xs) = (quicksort less) ++ [x] ++ (quicksort greater)
  where
    less = filter ( < x) xs
    greater = filter ( >= x) xs

-- poor man's selection sort
selectionsort [] = []
selectionsort xs = ys ++ (selectionsort zs)
  where
    y = minimum xs
    ys = filter (==y) xs
    zs = filter (/= y) xs

-- curried addition function.
-- add takes x and returns a function that takes y and returns x + y.
-- in haskell all functions are curried by default, so add x y = x + y
-- is equivalent.
--
-- Examples:
--   add 2 3  = 5
--   (add 2) 3 = 5
--
add :: Int -> Int -> Int
add x y = x + y


-- Partial application of add.
-- t is a function that adds 6 to its argument.
--
-- Examples:
--   t 4        = 10
--   t 0        = 6
--   map t [1,2,3] = [7,8,9]
--
t = add 6


-- Infinite list of ones.
-- Haskell's lazy evaluation allows working with infinite data structures.
--
-- Examples:
--   take 5 ones        = [1,1,1,1,1]
--   sum (take 100 ones) = 100
--
ones :: [Int]
ones = 1 : ones

-- Fibonacci sequence defined via list comprehension and recursion.
-- The list is infinite; use take to extract a prefix.
--
-- Examples:
--   take 10 fib = [0,1,1,2,3,5,8,13,21,34]
--   fib !! 6    = 8
--
fib :: [Integer]
fib = 0 : 1 : [x+y | (x,y) <- zip fib (tail fib)]

-- Simple recursive list sum.
-- Base case: the sum of an empty list is 0.
-- Recursive case: head plus the sum of the tail.
--
-- Examples:
--   sum' []          = 0
--   sum' [1,2,3,4,5] = 15
--   sum' [-3,5,10]   = 12
--
sum' :: [Int] -> Int
sum' [] = 0
sum' (x:xs) = x + (sum' xs)


-- Prepend an element to a list.
--
-- Examples:
--   app 0 [1,2,3] = [0,1,2,3]
--   app 'a' "bc"  = "abc"
--
app :: a -> [a] -> [a]
app x xs = x : xs

--
length' :: [a] -> Int
length' [] = 0
length' (_:xs) = 1 + length' xs

length2 :: [Int] -> Int
length2 []     = 0
length2 (x:xs) = if x > 0 then 1 + length2 xs else 1 + length2 xs

product' :: [Int] -> Int
product' [] = 1
product' (x:xs) = x * product' xs


main :: IO ()
main = do
  putStrLn "=== Lecture 01: Haskell Basics ==="

  putStrLn "\n-- Sorting --"
  print (quicksort [3,1,4,1,5,9,2,6 :: Int])
  print (quicksort "haskell")
  print (selectionsort [3,1,4,1,5 :: Int])

  putStrLn "\n-- Curried functions and partial application --"
  print (add 2 3)
  print (t 4)
  print (map t [1,2,3])

  putStrLn "\n-- Lazy infinite lists --"
  print (take 5 ones)
  print (take 10 fib)

  putStrLn "\n-- Recursive list functions --"
  print (sum' [1,2,3,4,5])
  print (app (0 :: Int) [1,2,3])
  print (length' [1,2,3,4,5 :: Int])
  print (length2 [1,2,3,4,5])
