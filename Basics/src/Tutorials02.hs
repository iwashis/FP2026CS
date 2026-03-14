module Tutorials02 (main) where

-- # Tail Recursion
--
-- 1. **Tail Recursion and GCD with Extended Input Processing**
--
--    Write a function `tailGCD :: Integral a => a -> a -> a` that 
--    computes the greatest common divisor (GCD) of two integers.

tailGCD :: Integral a => a -> a -> a
tailGCD x 0 = abs x 
tailGCD x y = tailGCD y (x `mod` y)

-- Euklid ? 
-- gcd (a,b) = gcd (b, a mod b)
-- gcd (a,0) = |a|

-- 2. **Tail Recursion and Quicksort Using an Explicit Stack**
--
--    Implement a version of the quicksort algorithm: 
--    `tailQuickSort :: Ord a => [a] -> [a]`, that avoids deep 
--    recursion by using an accumulator or explicit stack to manage the sublists that need to be sorted.


data StackElem a = Unsorted [a] | Sorted a 

tailQuickSort :: Ord a => [a] -> [a]
tailQuickSort list = go [Unsorted list] [] 
  where
   go [] acc = acc 
   go (Sorted elem : stack) acc = go stack (elem : acc)
   go (Unsorted [] : stack) acc = go stack acc 
   go (Unsorted (x:xs) : stack) acc = 
    let smaller = filter (< x) xs
        bigger  = filter (>= x) xs
    in go (Unsorted bigger : Sorted x : Unsorted smaller : stack) acc
   
-- tailQuickSort [3,4,1,5,-1,6]
-- [Unsorted [3,4,1,5,-1,6]], []
-- pivot = 3, smaller = [1,-1], bigger = [4,5,6]
-- [Unsorted [4,5,6], Sorted [3], Unsorted [1,-1]], []
-- [Unsorted [5,6], Sorted [4], Unsorted [], Sorted [3], Unsorted [1,-1]], []
-- [Unsorted [6], Sorted [5], Unsorted [], Sorted [4], Unsorted [], Sorted [3], Unsorted [1,-1]], []
-- [Unsorted [], Sorted [6], Unsorted [], Sorted [5], Unsorted [], Sorted [4], Unsorted [], Sorted [3], Unsorted [1,-1]], []
-- [Unsorted [1,-1]] [3,4,5,6]

-- 3. **Tail Recursion and Computing the Power Set**
--
--    Write a function `tailPowerSet :: [a] -> [[a]]` that computes 
--    the power set of a given list using tail recursion. 
--
--    Make sure that:
--    - You use an accumulator that incrementally builds the power set.
--    - You avoid the creation of intermediate thunks when merging subsets.
--    - The function works efficiently even for moderately sized lists.
--
-- 4. **Tail Recursion and Tree Traversal**
--
--    For a binary tree defined as:
--    ```haskell
--    data Tree a = Empty | Node a (Tree a) (Tree a)
--    ```
--    write a function `preorder :: Tree a -> [a]` that visits the nodes of 
--    the tree in the following order: first the current node, 
--    then its left subtree, and finally its right subtree, returning the values in that order.

data Tree a = Empty | Node a (Tree a) (Tree a)
badPreorder :: Tree a -> [a]
badPreorder Empty = []
badPreorder (Node x left right) = x : (badPreorder left ++ badPreorder right)


preorder :: Tree a -> [a]
preorder tree = go [tree] []
  where 
    go [] acc = reverse acc
    go (Empty:stack) acc = go stack acc 
    go ((Node x left right):stack) acc = go (left : right : stack) (x : acc)

-- --5. **Tail Recursion and Expression Evaluation Using an Explicit Stack**
--
--    Consider arithmetic expressions built from integer literals, addition, and multiplication:
--    ```haskell
--    data Expr = Lit Int | Add Expr Expr | Mul Expr Expr
--    ```
--    A naive recursive evaluator is not tail-recursive because it must return to the call site to combine the results of subexpressions.
--
--    Implement a tail-recursive evaluator `evalExpr :: Expr -> Int` by using an explicit stack to simulate the call stack. Your stack should track the pending work left to do after each subexpression is evaluated (for example, which subexpressions still need to be processed and how their results should be combined). The function must not use any non-tail recursive calls.
main = do
  putStrLn "=== Tutorials 02 ==="
  
  putStrLn "GCD in tail recursion"
  print (tailGCD 10 15)
 
  putStrLn "Quicksort tail recursion"
  print (tailQuickSort [3,4,1,5,-1,6])
  putStrLn "Preorder tail recursion"
  let treeExample = Node 3 (Node 5 (Node (-1) Empty Empty) Empty) (Node 10 Empty Empty)
  print (badPreorder treeExample)
  print (preorder treeExample)
