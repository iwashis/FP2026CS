# ADTs and Typeclasses

1. **Binary Search Tree Dictionary with Balancing**

   Define an algebraic data type representing a binary search tree (BST) that acts as a dictionary mapping keys to values. Implement the following operations:
   - *Insert*: Add a key-value pair to the tree.
   - *Lookup*: Retrieve the value associated with a given key.
   - *Delete*: Remove a key (and its associated value) from the tree.
   - *Update*: Modify the value associated with an existing key.
   - *Balance*: Implement a balancing procedure (e.g. AVL or red-black tree) so that the tree remains balanced after insertions and deletions.

2. **Expression Interpreter with Differentiation and Simplification**

   Define an algebraic data type representing arithmetic expressions, including variables, numeric constants, addition, multiplication, and exponentiation. Write functions that:
   - *Evaluate*: Compute the numeric value of an expression given a mapping from variable names to numbers.
   - *Differentiate*: Symbolically differentiate an expression with respect to a given variable.
   - *Simplify*: Reduce an expression to a simpler form by applying algebraic identities (e.g. eliminating zero terms, collapsing constant subexpressions, combining like terms).

3. **Custom Lazy List with Infinite Support**

   Define your own list type, for example:
   ```haskell
   data MyList a = Nil | Cons a (MyList a)
   ```
   that supports lazy evaluation. Implement the following functions:
   - `myMap`: Analogous to `map`.
   - `myFoldr`: A right fold (`foldr`) that can operate on infinite lists when the combining function is non-strict in its second argument.
   - `myFilter`: Analogous to `filter`.

   Then define `Semigroup`, `Monoid`, `Functor`, and `Foldable` instances for `MyList`.

4. **Graph Representation and Algorithms**

   Define an algebraic data type representing an undirected graph whose vertices can store arbitrary data. Write functions that:
   - *Depth-First Search (DFS)*: Traverse the graph starting from a given vertex, returning the vertices visited in order.
   - *Cycle Detection*: Determine whether the graph contains a cycle.
   - *Path Finding*: Find a path between two vertices, returning `Nothing` if no path exists.

5. **Rose Trees**

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

   Write an `Eq` instance for `RoseTree a` (assuming `Eq a`).

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
