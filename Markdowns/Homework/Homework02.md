# Homework 02

Throughout this homework we use the following sequence type:
```haskell
data Sequence a = Empty | Single a | Append (Sequence a) (Sequence a)
```
A `Sequence a` represents a sequence of values of type `a`. `Empty` is the empty sequence, `Single x` is a one-element sequence, and `Append l r` is the concatenation of two subsequences.

1. **Functor for Sequence**

   Write a `Functor` instance for `Sequence`:
   ```haskell
   instance Functor Sequence where
       fmap :: (a -> b) -> Sequence a -> Sequence b
   ```

2. **Foldable for Sequence**

   Write a `Foldable` instance for `Sequence` by implementing `foldMap`:
   ```haskell
   instance Foldable Sequence where
       foldMap :: Monoid m => (a -> m) -> Sequence a -> m
   ```
   Your traversal order should be *left-to-right*: the left subsequence of an `Append` is processed before the right. Once the instance is in place, use library functions from `Foldable` to define:
   - `seqToList :: Sequence a -> [a]` — returns all elements in left-to-right order
   - `seqLength :: Sequence a -> Int` — returns the number of elements

3. **Semigroup and Monoid for Sequence**

   Define `Semigroup` and `Monoid` instances for `Sequence a`:
   ```haskell
   instance Semigroup (Sequence a) where
       (<>) :: Sequence a -> Sequence a -> Sequence a

   instance Monoid (Sequence a) where
       mempty :: Sequence a
   ```

4. **Tail Recursion and Sequence Search**

   Write a function
   ```haskell
   tailElem :: Eq a => a -> Sequence a -> Bool
   ```
   that searches for an element in a `Sequence` using tail recursion with an explicit stack (a list of `Sequence a` values) to manage subsequences still to be inspected. The function should not grow the call stack in proportion to the nesting depth — instead, push unvisited subtrees onto the accumulator stack and loop.

5. **Tail Recursion and Sequence Flatten**

   Write a tail-recursive function
   ```haskell
   tailToList :: Sequence a -> [a]
   ```
   that converts a `Sequence a` to a list `[a]` in left-to-right order. 

5. **Tail Recursion and Reverse Polish Notation**

   A *Reverse Polish Notation* (RPN) expression is a sequence of tokens:
   ```haskell
   data Token = TNum Int | TAdd | TSub | TMul | TDiv
   ```
   Evaluation uses a stack: numbers are pushed; operators pop two values, apply the operation, and push the result back.

   Write a tail-recursive function
   ```haskell
   tailRPN :: [Token] -> Maybe Int
   ```
   that processes the token list using a list as the operand stack accumulator. Return `Nothing` for malformed expressions (too few operands, tokens remaining after the final result) or division by zero.


6. **Expressing functions via `foldr` and `foldl`**

    Without using explicit recursion, implement the following functions using `foldr` and/or `foldl`:

    (a) `myReverse :: [a] -> [a]` — reverses a list. Use `foldl`. Explain why `foldl` is the natural choice here (and why a naïve `foldr` version would be inefficient).

    (b) `myTakeWhile :: (a -> Bool) -> [a] -> [a]` — returns the longest prefix of elements satisfying the predicate (e.g. `myTakeWhile even [2,4,3,6] = [2,4]`). Use `foldr`. Explain why `foldr` can stop early on an infinite list here thanks to lazy evaluation, while a `foldl` version cannot.

    (c) `decimal :: [Int] -> Int` — interprets a list of digits as a decimal number, e.g. `decimal [1,2,3] = 123`.

7. **Run-length encoding via folds**

   *Run-length encoding* compresses a list by replacing consecutive runs of the same element with a pair of the element and its count.

   (a) Implement `encode :: Eq a => [a] -> [(a, Int)]` using `foldr`. For example:
   ```haskell
   encode "aaabccca" = [('a',3),('b',1),('c',3),('a',1)]
   ```

   (b) Implement `decode :: [(a, Int)] -> [a]` using `foldr` (and `replicate`). For example:
   ```haskell
   decode [('a',3),('b',1),('c',3),('a',1)] = "aaabccca"
   ```
