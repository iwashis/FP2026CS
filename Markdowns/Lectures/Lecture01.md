# Introduction to Functional Programming in Haskell


## Working Interactively with GHC

Haskell comes with an interactive interpreter called GHCi (Glasgow Haskell Compiler Interactive) that lets you experiment with code and see results immediately. To launch GHCi, simply type `ghci` in your terminal:

```
$ ghci
GHCi, version 8.10.7: https://www.haskell.org/ghc/  :? for help
>
```

In GHCi you can enter expressions and get their values right away:

```
> 2 + 2
4
> "Hello, " ++ "world!"
"Hello, world!"
```

## Types and the Type System

One of the most important features of Haskell is its strong static type system. Every expression in Haskell has a type that is checked at compile time. You can inspect the type of an expression with the `:t` or `:type` command:

```
> :t 42
42 :: Num p => p
> :t "Haskell"
"Haskell" :: [Char]
> :t True
True :: Bool
```

Note that the type of `42` is polymorphic — it can be any numeric type (`Int`, `Integer`, `Float`, etc.). The type of the string `"Haskell"` is `[Char]`, i.e. a list of characters.

You can also define your own variables and check their types:

```
> let x = 10
> let s = "Functional programming"
> :t x
x :: Num p => p
> :t s
s :: [Char]
```

In Haskell you can also provide explicit type annotations:

```
> let y :: Int; y = 20
> :t y
y :: Int
```

## Quicksort

Let's look at an elegant implementation of the quicksort algorithm in Haskell. It is a great example of the conciseness and declarative style of functional programming. It works recursively according to the following principle:

1. If the list is empty, return an empty list (base case).
2. Otherwise, choose the first element as the pivot.
3. Split the remaining elements into two groups: those smaller than the pivot, and those greater than or equal to it.
4. Recursively sort both sublists and concatenate them with the pivot in the middle.

The entire implementation fits in just a few lines:

```haskell
quicksort :: (Ord a) => [a] -> [a]
quicksort [] = []
quicksort (x : xs) = quicksort le ++ [x] ++ quicksort gr
  where
    le = filter (< x) xs
    gr = filter (>= x) xs
```

Notice the type signature `(Ord a) => [a] -> [a]`, which says that the function takes a list of elements of any type `a`, provided that type belongs to the `Ord` type class (i.e. its elements can be compared), and returns a list of elements of the same type.

Let's try a few examples in GHCi:

```
> quicksort [3,1,4,1,5,9,2,6]
[1,1,2,3,4,5,6,9]
> quicksort "haskell"
"aehklls"
> quicksort []
[]
> quicksort [7,7,7,7]
[7,7,7,7]
> quicksort [-10,5,0,-3,8]
[-10,-3,0,5,8]
```

## Currying

In functional languages like Haskell, functions are *curried* (named after the mathematician Haskell Curry). This means that a function taking multiple arguments is treated as a series of single-argument functions.

Consider a function that adds two numbers:

```haskell
add :: Int -> (Int -> Int)
add x = \y -> x + y
```

The type signature `Int -> (Int -> Int)` tells us that `add` takes an integer and returns a function that in turn takes an integer and returns an integer. In other words, `add` takes argument `x` and returns a function that takes argument `y` and returns the sum `x + y`.

In practice we can use this function in two ways:

```
> add 2 3
5
> (add 2) 3
5
```

In the first case we supply both arguments at once. In the second we first create the partially applied function `(add 2)` and then apply it to `3`.

Note that in Haskell all functions are curried by default, so you can also write this function more concisely:

```haskell
add :: Int -> Int -> Int
add x y = x + y
```

## Partial Application

Currying enables *partial application*: creating a new function by supplying only some of the arguments to a multi-argument function.

For example, we can create a function that adds 6 to its argument:

```haskell
t = add 6
```

Now `t` is a single-argument function:

```
> t 4
10
> t 0
6
> map t [1,2,3]
[7,8,9]
```

Partial application is extremely useful in functional programming because it lets you create new functions in a straightforward way and makes function composition easier.

We can also partially apply built-in functions:

```
> let addOne = (+ 1)
> addOne 10
11
> let isPositive = (> 0)
> isPositive 5
True
> isPositive (-3)
False
```

## Infinite Lists

One of Haskell's unique features is *lazy evaluation*, which allows you to work with infinite data structures. Because of this, we can define infinite lists that are only computed as far as needed.

Here is an example of an infinite list of ones:

```haskell
ones = 1 : ones
```

This definition may look recursive and infinite — and it is! Thanks to lazy evaluation, Haskell only computes as many elements as are required:

```
> take 5 ones
[1,1,1,1,1]
> sum (take 100 ones)
100
```

Another example is an infinite list of natural numbers:

```haskell
naturals = 0 : map (+1) naturals
```

We can now easily take any number of natural numbers:

```
> take 10 naturals
[0,1,2,3,4,5,6,7,8,9]
```

Or find the even ones:

```
> take 10 (filter even naturals)
[0,2,4,6,8,10,12,14,16,18]
```

## The Fibonacci Sequence

The Fibonacci sequence is a classic example of recursion. In Haskell we can define it in a remarkably elegant way using list comprehensions and recursion:

```haskell
fib = 0 : 1 : [x + y | (x, y) <- zip fib (drop 1 fib)]
```

This definition is almost a direct reflection of the mathematical definition of the Fibonacci sequence: each element is the sum of the two preceding ones. Notice that we define `fib` in terms of itself!

Let's try a few examples:

```
> take 10 fib
[0,1,1,2,3,5,8,13,21,34]
> fib !! 6  -- element at index 6 (the seventh element)
8
> fib !! 20
6765
```

We can also find Fibonacci numbers that satisfy certain conditions:

```
> take 5 (filter (>100) fib)
[144,233,377,610,987]
```

## Recursion

Recursion is the fundamental mechanism in functional programming, replacing the traditional loops found in imperative languages. Let's look at a simple function that sums the elements of a list:

```haskell
sum' :: [Int] -> Int
sum' [] = 0
sum' (x : xs) = x + sum' xs
```

Let's test the function on a few examples:

```
> sum' []
0
> sum' [1,2,3,4,5]
15
> sum' [-3,5,10]
12
```

In practice we often use higher-order functions such as `map`, `filter`, and `foldr`:

```
> map (*2) [1,2,3,4,5]  -- double each element
[2,4,6,8,10]
> filter even [1,2,3,4,5]  -- select even elements
[2,4]
> foldr (+) 0 [1,2,3,4,5]  -- summation (equivalent to sum')
15
```
