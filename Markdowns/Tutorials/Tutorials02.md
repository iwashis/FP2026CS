# Tail Recursion

1. **Tail Recursion and GCD with Extended Input Processing**

   Write a function `tailGCD :: Integral a => a -> a -> a` that computes the greatest common divisor (GCD) of two integers.

2. **Tail Recursion and Quicksort Using an Explicit Stack**

   Implement a version of the quicksort algorithm: `tailQuickSort :: Ord a => [a] -> [a]`, that avoids deep recursion by using an accumulator or explicit stack to manage the sublists that need to be sorted.

3. **Tail Recursion and Computing the Power Set**

   Write a function `tailPowerSet :: [a] -> [[a]]` that computes the power set of a given list using tail recursion. Make sure that:
   - You use an accumulator that incrementally builds the power set.
   - You avoid the creation of intermediate thunks when merging subsets.
   - The function works efficiently even for moderately sized lists.

4. **Tail Recursion and Summing a Nested List Structure**

   Define a recursive type for nested lists:
   ```haskell
   data NestedList a = Elem a | List [NestedList a]
   ```
   Then write a tail-recursive function `sumNested :: Num a => NestedList a -> a` that computes the sum of all elements in the nested list.

5. **Tail Recursion and Tree Traversal**

   For a binary tree defined as:
   ```haskell
   data Tree a = Empty | Node a (Tree a) (Tree a)
   ```
   write a function `preorder :: Tree a -> [a]` that visits the nodes of the tree in the following order: first the current node, then its left subtree, and finally its right subtree, returning the values in that order.

6. **Rose Trees**

A *rose tree* (also called a *multi-way tree* or *ordered tree*) is a generalisation of a binary tree in which each node may have any number of children — zero, one, two, or more — and the order of those children is significant. The name comes from the resemblance of a fully-branched tree to a rose, and was popularised in functional programming by Lambert Meertens.

Where binary trees force exactly two subtrees per node (padding with explicit empty cases), a rose tree lets the list of children grow or shrink naturally at every level, making it a closer match to many real hierarchical structures.

**Where are rose trees used?**

- **File systems.** A directory is a node whose children are either files (leaves) or subdirectories (inner nodes). The number of entries in a directory is not fixed, so a binary tree would be an awkward fit.
- **Abstract syntax trees (ASTs).** In a programming language, a `while` loop has two children (condition and body), an `if`-expression may have three (condition, then-branch, else-branch), and a function call has one child per argument. A rose tree represents this variable arity directly.
- **XML and HTML documents.** Each element node has an ordered list of child elements or text nodes. The DOM (Document Object Model) is precisely a rose tree.


A *rose tree* (or multi-way tree) is a tree where each node holds a value and an arbitrary number of children:
```haskell
data RoseTree a = RoseNode a [RoseTree a]
```
For example, `RoseNode 1 [RoseNode 2 [], RoseNode 3 [RoseNode 4 []]]` represents a tree with root 1, two children 2 and 3, and 4 as a child of 3.

a. **Show instance for RoseTree**

   Write a `Show` instance for `RoseTree a` (assuming `Show a`) that displays a rose tree in a readable nested form. For example, the tree above might display as:
   ```
   1 [2 [], 3 [4 []]]
   ```
   Do not use `deriving Show` — write the instance by hand.

b. **Eq instance for RoseTree**

   Write an `Eq` instance for `RoseTree a` (assuming `Eq a`) that considers two rose trees equal if and only if they have the same root value and the same sequence of children (recursively). Again, do not use `deriving Eq`.

c. **Functor instance for RoseTree**

   Write a `Functor` instance for `RoseTree`:
   ```haskell
   instance Functor RoseTree where
       fmap :: (a -> b) -> RoseTree a -> RoseTree b
   ```
   The instance should apply the function to every value in the tree while preserving its shape. Verify the two functor laws:
   - **Identity**: `fmap id t == t`
   - **Composition**: `fmap (f . g) t == (fmap f . fmap g) t`

d. **Foldable instance for RoseTree**

   Write a `Foldable` instance for `RoseTree` by implementing `foldMap`:
   ```haskell
   instance Foldable RoseTree where
       foldMap :: Monoid m => (a -> m) -> RoseTree a -> m
   ```
   The traversal order should be *pre-order*: process the root value first, then fold over the children left to right. Once the instance is defined, use it to implement:
   - `roseToList :: RoseTree a -> [a]` — collects all values in pre-order
   - `roseDepth  :: RoseTree a -> Int` — returns the depth of the tree (root has depth 1)
