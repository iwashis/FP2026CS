---
theme: ./lighttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 5


## Lecture code
Lecture05.hs

---

# The List Monad

The `return` and `>>=` operations have the following types in this case:
```haskell
return :: a -> [a]

(>>=)  :: [a] -> (a -> [b]) -> [b]
```

Think of a list as representing *non-deterministic* computation — a value that could be any of several possibilities. Then `>>=` applies a non-deterministic function to each possibility and collects all outcomes.

## Exercise: write the definition of the Monad instance for [].

---

## List Monad — examples

```haskell
triple = \x -> [x,x,x]
["Bunny"] >>= triple >>= triple
-- ["Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny"]
```

## Pythagorean triples — non-deterministic search
```haskell
pythTriples :: [(Int, Int, Int)]
pythTriples = do
  a <- [1..20]
  b <- [a..20]
  c <- [b..20]
  if a*a + b*b == c*c then return (a,b,c) else []

-- [(3,4,5),(5,12,13),(6,8,10),(8,15,17),(9,12,15)]
```
Each `<-` picks one element from a list. The `if ... then return ... else []` acts as a filter. This is non-determinism in action.

---

# The List Monad — in other languages

`>>=` for lists is `concatMap` — or `flat_map` as it is known in most languages. The Pythagorean triples example translates directly.

## Rust — iterators with `flat_map`
```rust
let triples: Vec<(i32,i32,i32)> =
    (1..=20).flat_map(|a|
        (a..=20).flat_map(move |b|
            (b..=20).filter(move |&c| a*a + b*b == c*c)
                    .map(move |c| (a, b, c))
    )).collect();
```
Each `flat_map` is `>>=` — it expands one element into many, then flattens.

---

# Do notation and list comprehensions

Do notation for the list monad is closely related to list comprehensions:
```haskell
fib = 0 : 1 : do
      (x,y) <- zip fib $ tail fib
      return (x+y)
```
Using syntactic sugar (list comprehension) we get:
```haskell
fib = 0 : 1 : [ x+y | (x,y) <- zip fib $ tail fib ]
```

In general, list comprehensions are just do notation for `[]` with a more compact syntax. Guards in comprehensions correspond to the filter pattern we saw above:
```haskell
[x | x <- [1..20], even x]   ==   do { x <- [1..20]; if even x then [x] else [] }
```

---

# State Monad — motivation

Imagine you are writing a compiler and need to generate unique variable names: `_t0`, `_t1`, `_t2`, … You need a counter that increases every time you use it. In Python or C++ you would just use a mutable variable. In Haskell, every function is pure — so you have to pass the counter around by hand:
```haskell
freshName :: Int -> (String, Int)
freshName n = ("_t" ++ show n, n + 1)

twoNames :: Int -> ((String, String), Int)
twoNames n0 = let (name1, n1) = freshName n0
                  (name2, n2) = freshName n1
              in  ((name1, name2), n2)
```
This works, but it is tedious and error-prone — it is easy to accidentally write `freshName n0` twice instead of `freshName n1`. The more steps you have, the worse it gets.

---

# State Monad: the type

Look at the type of `freshName` again:
```haskell
freshName :: Int -> (String, Int)
--           ^^^    ^^^^^^^^ ^^^
--          state    result  new state
```
Every stateful function has this shape: **old state in, result + new state out**. The State monad wraps exactly this pattern into a type:
```haskell
newtype State s a = State { runState :: s -> (a, s) }
```

- `s` — the type of the state (e.g. `Int` for our counter)
- `a` — the type of the result (e.g. `String` for the generated name)
- A `State s a` value is a *recipe*: "give me the current state, and I will give you back a result and the updated state"

`runState` unwraps the recipe and actually runs it:
```haskell
ghci> runState freshName 0    -- ("_t0", 1)
ghci> runState freshName 42   -- ("_t42", 43)
```

---

# Exercise: Write Functor and Monad instances for State s a

1. Define a new data type `State1 s a` isomorphic to the original one.

2. Define the `Functor` instance:
```haskell
instance Functor (State1 s) where
  fmap f (State1 g) = ???
  -- Hint: run g on the state, apply f to the result, pass state along
```

3. Define the `Monad` instance:
```haskell
instance Monad (State1 s) where
  return a = ???
  -- Hint: produce a without changing the state

  (State1 g) >>= f = ???
  -- Hint: run g, feed the result to f, thread the state through
```

---

# Basic state operations

Once we have the Monad instance, we can define convenient helpers. Think of the state as a mutable variable that you can read, write, or update:
```haskell
get :: State s s              -- read the current value    (like x in C++)
get = State (\s -> (s, s))

put :: s -> State s ()        -- overwrite with a new value (like x = 5)
put s = State (\_ -> ((), s))

modify :: (s -> s) -> State s ()  -- apply a function       (like x += 1)
modify f = State (\s -> ((), f s))
```

These are the building blocks — most stateful code is written using `get`, `put`, and `modify` rather than constructing `State` values directly.

## The fresh-name generator, revisited
```haskell
freshName :: State Int String
freshName = do
  n <- get              -- read the counter
  put (n + 1)           -- increment it
  return ("_t" ++ show n)

twoNames :: State Int (String, String)
twoNames = do
  x <- freshName        -- no manual threading!
  y <- freshName        -- the monad passes the counter for us
  return (x, y)

ghci> runState twoNames 0
-- (("_t0", "_t1"), 2)
```

---

# State Monad — tracing the execution

Let's see exactly how the monad threads the state behind the scenes. Consider:
```haskell
tick :: State Int Int     -- same shape as freshName, but returns the counter itself
tick = do
  n <- get
  put (n + 1)
  return n
```

## Step-by-step trace of `runState (do { tick; tick; tick }) 0`:
```
               state    result
  start:         0
  1st tick:      0 → 1     0      -- get returns 0, put sets 1, return 0
  2nd tick:      1 → 2     1      -- get returns 1, put sets 2, return 1
  3rd tick:      2 → 3     2      -- get returns 2, put sets 3, return 2
  final:    result = 2, state = 3
```
Each `tick` reads the current counter, bumps it, and returns the old value — exactly like `counter++` in C++. The monad takes care of passing the updated counter from one `tick` to the next.

---

# State Monad — a stack example

A stack is just a list used as state:
```haskell
type Stack a = State [a]

push :: a -> Stack a ()
push x = modify (x:)

pop :: Stack a a
pop = do
  (x:xs) <- get
  put xs
  return x
```

## Usage
```haskell
stackOps :: Stack Int Int
stackOps = do
  push 1
  push 2
  push 3
  pop            -- removes 3
  a <- pop       -- removes 2
  return a

ghci> runState stackOps []
-- (2, [1])
```

