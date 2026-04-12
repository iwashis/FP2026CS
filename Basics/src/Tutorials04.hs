module Tutorials04 (main) where

-- # Monads and their applications
--
-- 1. **Maybe Monad — safe indexing and lookup chains**
--
--    a. Implement `safeIndex :: [a] -> Int -> Maybe a` that safely returns the element at a given index (0-based), returning `Nothing` if the index is out of bounds. 

naiveSafeIndex [] _ = Nothing 
naiveSafeIndex (x:_) 0 = Just x
naiveSafeIndex (x:xs) n = naiveSafeIndex xs (n-1)

head' :: [a] -> Maybe a
head' []    = Nothing
head' (x:_) = Just x

tail' :: [a] -> Maybe [a]
tail' []     = Nothing
tail' (_:xs) = Just xs

safeIndex :: Int -> [a] -> Maybe a
safeIndex 0 list = head' list
safeIndex n list = do 
  t <- tail' list 
  safeIndex (n-1) t   

-- >>= :: Maybe a -> (a -> Maybe b) -> Maybe b
--    b. Given two association lists (i.e. lists of key-value pairs):
--    ```haskell
--    students :: [(Int, String)]        -- student ID -> name
--    grades   :: [(String, [Int])]      -- name -> list of grades
--    ```
--    write a function `bestGrade :: [(Int, String)] -> [(String, [Int])] -> Int -> Maybe Int` that, given a student ID, looks up the student's name, then their list of grades, then returns the maximum grade. If any step fails (unknown ID, unknown name, or empty grade list), the result should be `Nothing`. Use `>>=` to chain the lookups. Then rewrite the same function using do notation.
--
-- 2. **Fish operator (>=>) in practice**
--
--    Implement the functions `safeTail :: [a] -> Maybe [a]` and `safeHead :: [a] -> Maybe a`,
--    which safely return the tail and head of a list, handling the empty list case.
--    Then use the Kleisli composition operator (`>=>`) to define `safeSecond :: [a] -> Maybe a`,
--    which safely returns the second element of a list.
--
--
-- 3. **List Monad and path exploration**
--
--    Write a function `knights :: (Int, Int) -> [(Int, Int)]` that, given a knight's position on a chessboard,
--    returns a list of all possible knight moves. Then implement a function `knightPaths :: Int -> (Int, Int) -> (Int, Int) -> [[(Int, Int)]]`
--    that finds all possible paths of length `n` moves from one position to another. Use the list monad and
--    the `>>=` operator to explore all possible paths.
--
-- 4. **Implementing a custom monad**
--
--    Implement your own monad `Logger a` that stores a value of type `a` together with a log
--    of operations (a list of strings). Define `Functor`, `Applicative`, and `Monad` instances for this type.
--    Write helper functions:
--    - `logMessage :: String -> Logger ()`
--    - `runLogger :: Logger a -> (a, [String])`
--
--    Then use this monad to implement a function `factorial :: Int -> Logger Int`
--    that computes the factorial and logs each step of the computation.
--
--
-- 5. **State Monad for tracking state**
--
--    Define a function `runningSum :: [Int] -> [Int]` that, given a list of integers, returns a list of partial sums.
--    For example, for the list `[1, 2, 3, 4]` the result should be `[1, 3, 6, 10]`. Implement this function
--    using the State monad, making use of `get`, `put`, and `runState` or `evalState`.
--
-- 6. **Writer Monad for accumulating results**
--
--    Implement a function `countNodes :: Tree a -> Writer (Sum Int) Int` that counts the nodes in a binary tree
--    using the Writer monad for accumulation. Define the tree type as
--    `data Tree a = Empty | Leaf a | Node a (Tree a) (Tree a)` and use the `tell` function in your solution.

main :: IO ()
main = do
  putStrLn "=== Tutorials 04 ==="
  print $ safeIndex 2 [1,2,3]
