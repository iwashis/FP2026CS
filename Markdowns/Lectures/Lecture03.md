# Folds in Haskell

## Basic Folds: foldl and foldr

Let us consider the two fundamental fold functions: `foldl` (left fold) and `foldr` (right fold).

```haskell
-- foldl (#) seed [a1..an] -> ((..(seed#a1)#a2#..)#an
-- foldr (*) seed [a1..an] -> a1*(a2*..(an*seed))..)
--
-- foldl :: (b -> a -> b) -> b -> [a] -> b
```

`foldl` folds a list from the left, starting from an initial value (seed) and applying the function cumulatively to each element. `foldr` folds a list from the right.

## Examples of Fold Applications

### Building the List of All Initial Sublists

A practical use of folds: the function `initl`, which builds the list of all prefixes:

```haskell
initl :: [a] -> [[a]]
initl = foldl f seed
  where
    seed = [[]]  -- initial value is a list containing the empty list
    f s c = s ++ [last s ++ [c]]  -- append a new sublist formed by adding c to the last sublist
```

`initl` uses `foldl` to build the result step by step.
We start with a list containing the empty list, then for each new element
we create a new sublist by appending it to the last sublist built so far.

Examples:
```
> initl "abc"
["","a","ab","abc"]
> initl [10,20,30]
[[],[10],[10,20],[10,20,30]]
```

The same function can be implemented using `foldr`:

```haskell
initr :: [a] -> [[a]]
initr = foldr f seed
  where
    seed = [[]]
    f x acc = [] : map (x:) acc
```

The difference lies in how the result is constructed — with `foldr` we start from the end of the list and build the result from the right.

### Sum of List Elements

The simplest fold example is computing the sum of a list:

```haskell
sumList :: [Int] -> Int
sumList = foldl (+) 0
```

Example:
```
> sumList [1,2,3,4,5]
15
```

Here `foldl` computes: `((((0+1)+2)+3)+4)+5 = 15`

### Reversing a List

Another classic example is reversing a list:

```haskell
reverseList :: [a] -> [a]
reverseList = foldl (\acc x -> x : acc) []
```

Example:
```
> reverseList [1,2,3]
[3,2,1]
```

Step by step:
1. `acc = [], x = 1 => x : acc = [1]`
2. `acc = [1], x = 2 => x : acc = [2,1]`
3. `acc = [2,1], x = 3 => x : acc = [3,2,1]`

### Counting Occurrences of an Element

Folds are also useful for data analysis, e.g. counting occurrences of an element:

```haskell
countOccurrences :: Eq a => a -> [a] -> Int
countOccurrences y = foldl (\acc x -> if x == y then acc + 1 else acc) 0
```

Example:
```
> countOccurrences 'a' "abracadabra"
5
```

## Folds on Custom Data Types

Haskell lets us extend the concept of folds to custom data types
by implementing the `Foldable` typeclass.
Let us define a binary tree and implement `Foldable` for it:

```haskell
data Tree a = EmptyTree | Leaf a | Node a (Tree a) (Tree a)
```

Some example trees:

```haskell
tree :: Tree String
tree = Node "a" (Node "b" EmptyTree (Leaf "c")) (Node "d" EmptyTree EmptyTree)

tree2 :: Tree Int
tree2 = Node 1 (Node 5 EmptyTree (Leaf 7)) (Node 3 EmptyTree EmptyTree)
```

Implementing `Foldable` for the tree:

```haskell
instance Foldable Tree where
    -- foldMap :: Monoid m => (a -> m) -> Tree a -> m
    -- Maps each element of the tree to a monoid and combines the results
    foldMap _ EmptyTree = mempty          -- empty tree is the monoid identity
    foldMap f (Leaf x)  = f x             -- a leaf is just the value mapped by f
    foldMap f (Node x left right) =
        foldMap f left <> f x <> foldMap f right

    -- foldr :: (a -> b -> b) -> b -> Tree a -> b
    -- Folds the tree "from the right"
    foldr _ seed EmptyTree = seed                    -- empty tree returns the seed
    foldr f seed (Leaf x)  = f x seed               -- leaf applies f to its value and seed
    foldr f seed (Node x left right) =
        foldr f (f x (foldr f seed right)) left
    -- Evaluation order: right subtree first, then the node, then the left subtree
```

By implementing `Foldable` for our tree we gain access to all functions
that work on `Foldable` types, such as `fold`, `foldMap`, `foldr`, `foldl`, etc.

### Examples of Using Folds on Trees

To demonstrate `Foldable` on trees, let us define a helper type `Any`
for checking whether a tree contains a given value:

```haskell
newtype Any = Any { getAny :: Bool }

instance Semigroup Any where
  (<>) (Any x) (Any y) = Any (x || y)

instance Monoid Any where
  mempty = Any False
```

Now we can write a function that checks whether a tree contains a given value:

```haskell
treeContains :: Eq a => a -> Tree a -> Bool
treeContains x = getAny . foldMap (\y -> Any (y == x))
```

Examples:
```
> treeContains 7 tree2
True
> treeContains 10 tree2
False
```

We can also collect all values from the tree into a list in inorder
(left subtree, node, right subtree):

```haskell
treeToList :: Tree a -> [a]
treeToList = foldMap (\x -> [x])
```

Examples:
```
> treeToList tree
["b","c","a","d"]
> treeToList tree2
[5,7,1,3]
```
