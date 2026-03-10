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
    go ((Node x left right):stack) acc = go (left : right : stack ) (x : acc)


-- 5. **Rose Trees**
--
-- A *rose tree* (also called a *multi-way tree* or *ordered tree*) 
-- is a generalisation of a binary tree in which each node 
-- may have any number of children — zero, one, two, or more — 
-- and the order of those children is significant. 
-- The name comes from the resemblance of a fully-branched tree to a rose, 
-- and was popularised in functional programming by Lambert Meertens.
--
--
-- A *rose tree* (or multi-way tree) is a tree where each node holds a value and an arbitrary number of children:
-- ```haskell
-- data RoseTree a = RoseNode a [RoseTree a]
-- ```
-- For example, `RoseNode 1 [RoseNode 2 [], RoseNode 3 [RoseNode 4 []]]` represents a tree with root 1, two children 2 and 3, and 4 as a child of 3.
--
-- a. **Show instance for RoseTree**
--
--    Write a `Show` instance for `RoseTree a` (assuming `Show a`) that displays a rose tree in a readable nested form. For example, the tree above might display as:
--    ```
--    1 [2 [], 3 [4 []]]
--    ```
--    Do not use `deriving Show` — write the instance by hand.
--
-- b. **Eq instance for RoseTree**
--
--    Write an `Eq` instance for `RoseTree a` (assuming `Eq a`) 
--
-- c. **Functor instance for RoseTree**
--
--    Write a `Functor` instance for `RoseTree`:
--    ```haskell
--    instance Functor RoseTree where
--        fmap :: (a -> b) -> RoseTree a -> RoseTree b
--    ```
--    The instance should apply the function to every value in the tree while preserving its shape. Verify the two functor laws:
--    - **Identity**: `fmap id t == t`
--    - **Composition**: `fmap (f . g) t == (fmap f . fmap g) t`
--
-- d. **Foldable instance for RoseTree**
--
--    Write a `Foldable` instance for `RoseTree` by implementing `foldMap`:
--    ```haskell
--    instance Foldable RoseTree where
--        foldMap :: Monoid m => (a -> m) -> RoseTree a -> m
--    ```
--    The traversal order should be *pre-order*: process the root value first, then fold over the children left to right. Once the instance is defined, use it to implement:
--    - `roseToList :: RoseTree a -> [a]` — collects all values in pre-order
--    - `roseDepth  :: RoseTree a -> Int` — returns the depth of the tree (root has depth 1)
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
