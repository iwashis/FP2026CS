module Tutorials03 where

import Prelude hiding (lookup)
import Data.List (intercalate)
-- # ADTs and Typeclasses
--
-- 1. **Binary Search Tree Dictionary with Balancing**
--
--    Define an algebraic data type representing a binary search tree (BST) that acts as a dictionary mapping keys to values. Implement the following operations:
--    - *Insert*: Add a key-value pair to the tree.
--    - *Lookup*: Retrieve the value associated with a given key.

data BST a = Empty | Node a (BST a) (BST a) deriving (Show, Eq)

insert :: Ord key =>  key -> value -> BST (key, value) -> BST (key, value)
insert k v Empty = Node (k,v) Empty Empty 
insert k v (Node node@(k',v') left right)
  | k < k' = Node node (insert k v left) right
  | k > k' = Node node left (insert k v right)
  | otherwise = Node (k,v) left right

lookup :: Ord key => key -> BST (key, value) -> Maybe value
lookup k Empty = Nothing
lookup k (Node (k', v') left right)
  | k == k' = Just v'
  | k < k'  = lookup k left 
  | k > k'  = lookup k right 

--    - *Delete*: Remove a key (and its associated value) from the tree.
--    - *Update*: Modify the value associated with an existing key.
--    - *Balance*: Implement a balancing procedure (e.g. AVL or red-black tree) so that the tree remains balanced after insertions and deletions.
--
-- 2. **Expression Interpreter with Differentiation and Simplification**
--
--    Define an algebraic data type representing arithmetic expressions, including variables, numeric constants, addition, multiplication, and exponentiation. Write functions that:
--    - *Evaluate*: Compute the numeric value of an expression given a mapping from variable names to numbers.
--    - *Differentiate*: Symbolically differentiate an expression with respect to a given variable.
--    - *Simplify*: Reduce an expression to a simpler form by applying algebraic identities (e.g. eliminating zero terms, collapsing constant subexpressions, combining like terms).
--
data Expr = Lit Int | Add Expr Expr | Mul Expr Expr
  deriving (Show)

data Frame
  = EvalRight (Int -> Int -> Int) Expr   -- need to eval right branch, then combine
  | ApplyOp   (Int -> Int -> Int) Int    -- left value in hand; combine with current

type Stack = [Frame]

-- Public entry point
evalExpr :: Expr -> Int
evalExpr expr = go expr []
  where
    go (Lit n) [] = n
    go (Lit n) ((ApplyOp op val):stack) = go (Lit $ op val n) stack
    go (Lit n) ((EvalRight op e):stack) = go e ((ApplyOp op n):stack)
    go (Add e1 e2) stack = go e1 ((EvalRight (+) e2) : stack) 
    go (Mul e1 e2) stack = go e1 (EvalRight (*) e2 : stack)

-- 3. **Graph Representation and Algorithms**
--
--    Define an algebraic data type representing an undirected graph whose vertices can store arbitrary data. Write functions that:
--    - *Depth-First Search (DFS)*: Traverse the graph starting from a given vertex, returning the vertices visited in order.
--    - *Cycle Detection*: Determine whether the graph contains a cycle.
--    - *Path Finding*: Find a path between two vertices, returning `Nothing` if no path exists.
--
-- 4. **Rose Trees**
--
data RoseTree a = RoseNode a [RoseTree a]
-- For example, `RoseNode 1 [RoseNode 2 [], RoseNode 3 [RoseNode 4 []]]` represents a tree with root 1, two children 2 and 3, and 4 as a child of 3.
--
-- a. **Show instance for RoseTree**
instance Show a => Show (RoseTree a) where
  -- show :: Show a => Show (RoseTree a) -> String
  show (RoseNode x list) = show x ++  " " ++ show list
--    Write a `Show` instance for `RoseTree a` (assuming `Show a`) that displays a rose tree in a readable nested form. For example, the tree above might display as:
--    ```
--    1 [2 [], 3 [4 []]]
--    ```
--    Do not use `deriving Show` — write the instance by hand.
--
-- b. **Eq instance for RoseTree**

instance Eq a => Eq (RoseTree a) where
   -- (==) :: Eq a => RoseTree a -> RoseTree a -> Bool
  (RoseNode x xlist) == (RoseNode y ylist) = x == y &&  xlist == ylist
--    Write an `Eq` instance for `RoseTree a` (assuming `Eq a`).
--
-- c. **Functor instance for RoseTree**
--
--    Write a `Functor` instance for `RoseTree`:
instance Functor RoseTree where
  -- fmap :: (a -> b) -> RoseTree a -> RoseTree b
  fmap f (RoseNode x list) = RoseNode (f x) $ map (fmap f) list 

--    Write a `Foldable` instance for `RoseTree` by implementing `foldMap`:
instance Foldable RoseTree where
  -- foldMap :: Monoid m => (a -> m) -> RoseTree a -> m
  foldMap f (RoseNode x trees) = (f x) <> mconcat (fmap (foldMap f) trees) 
--    The traversal order should be *pre-order*: process the root value first, then fold over the children left to right. Once the instance is defined, use it to implement:
--    - `roseToList :: RoseTree a -> [a]` — collects all values in pre-order
roseToList :: RoseTree a -> [a]
roseToList tree = foldMap (\x -> [x]) tree
-- # Foldables
--
-- 1. **Implementing map and filter using folds**
--
--    Implement the functions `myMap :: (a -> b) -> [a] -> [b]` and `myFilter :: (a -> Bool) -> [a] -> [a]`
--    using both `foldr` and `foldl`. Compare their behaviour and performance in the context of lazy evaluation.

-- foldl (#) seed [a1..an] -> ((..(seed#a1)#a2#..)#an
-- foldr (*) seed [a1..an] -> a1*(a2*..(an*seed))..)

myMap :: (a->b) -> [a] -> [b]
myMap f list = foldl (\s x -> s ++ [f x]) [] list

myFilter :: (a -> Bool) -> [a] -> [a]
myFilter predicate list = foldl (\s x -> if predicate x then s ++ [x] else s ) [] list 
--
-- 2. **Fold with accumulation control**
--
--    Implement the function `foldlWithControl :: (b -> a -> Either b c) -> b -> [a] -> Either b c`, which
--    works like `foldl`, but allows aborting the computation at any point, returning the current accumulator
foldlWithControl :: (b -> a -> Either b c) -> b -> [a] -> Either b c
-- data Either a b = Left a | Right b
foldlWithControl f seed [] = Left seed  
foldlWithControl f seed (x:xs) = 
  case f seed x of
    Left seed'  -> foldlWithControl f seed' xs 
    Right cont  -> Right cont 

--    wrapped in `Left` or the final result in `Right`. Then use this function to implement:
--    - `findFirstThat :: (a -> Bool) -> [a] -> Maybe a` — finds the first element satisfying a predicate

-- Maybe a ~ Either () a
findFirstThat :: (a -> Bool) -> [a] -> Either () a
findFirstThat predicate list = foldlWithControl (\_ x -> if predicate x then Right x else Left ()) () list  
--    - `takeWhileSum :: (Num a, Ord a) => a -> [a] -> [a]` — returns the longest prefix of a list whose sum does not exceed the given value
--    - `findSequence :: Eq a => [a] -> [a] -> Maybe Int` — finds the index of the first occurrence of a sublist in a list
-- 3. **Reversing folds**
--
--    Implement the function `unfoldl :: (b -> Maybe (b, a)) -> b -> [a]`, which is the inverse of `foldl` —
--    it generates a list from an initial state. Use it to implement:
--    - `countdown :: Int -> [Int]` — generates a countdown from n to 1
--    - `fib :: Int -> [Int]` — generates the first n Fibonacci numbers
--    - `iterate' :: (a -> a) -> a -> [a]` — your own implementation of the standard `iterate` function
--    - `decToBin :: Int -> [Int]` — converts a decimal number to its binary representation (a list of 0s and 1s)
main =  do
  let roseTree = RoseNode 1 [RoseNode 2 [RoseNode 5 []], RoseNode 3 []]
  let roseTree2 = RoseNode 1 [RoseNode 3 []]
  print roseTree 
  print $ roseTree == roseTree
  print $ roseTree == roseTree2
  print $ (*2) <$> roseTree
  let expr = Mul (Add (Lit 2) (Lit 5)) (Add (Lit 6) (Lit 7))
  print $ evalExpr expr
  print $ foldMap (\t-> [t]) roseTree
  print $ sum roseTree
  print $ myMap (+2) [1,2,3,4]
