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

# Bonus Questions

a. **Tail Recursion and BST Search**
   For a BST defined as `data BST a = Empty | Node a (BST a) (BST a)`, write a function `tailSearch :: Ord a => a -> BST a -> Bool` that searches for a given element in the tree using tail recursion with an explicit stack or accumulator to manage the search state.

b. **Tail Recursion and Finding the Minimum Element**
   Write a function `tailMinimum :: Ord a => [a] -> a` that returns the smallest element of a non-empty list, using tail recursion with an accumulator to eliminate unnecessary lazy thunks.

c. **Tail Recursion and Evaluation of Arithmetic Expressions**
   Define an abstract data type for arithmetic expressions:
   `data Expr = Val Int | Add Expr Expr | Mul Expr Expr | Sub Expr Expr`
   Then write a function `tailEval :: Expr -> Int` that evaluates a given expression using tail recursion with appropriate accumulators to store partial results.
