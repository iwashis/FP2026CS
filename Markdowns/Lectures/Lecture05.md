# The List Monad & The State Monad

## The List Monad

We have already met `Maybe` as a monad — it captures *computations that may fail*. The list type `[]` is also a monad, and it captures something different: *computations that may produce many results*.

Specialised to lists, the monad operations have types:

```haskell
return :: a -> [a]
(>>=)  :: [a] -> (a -> [b]) -> [b]
```

Think of a list as a *non-deterministic* computation — a value that could be any of several possibilities. Then `(>>=)` applies a non-deterministic function to each possibility and collects all the outcomes.

### Exercise: Write the Monad instance for `[]`

We will reproduce the standard library's instance on a hand-rolled copy of lists, so that nothing happens by magic:

```haskell
data MyList a = Nil | NonEmptyList a (MyList a)
    deriving (Show, Functor)

concat' :: MyList a -> MyList a -> MyList a
concat' Nil list = list
concat' (NonEmptyList x rest) list = NonEmptyList x (concat' rest list)

instance Applicative MyList where
  pure x = NonEmptyList x Nil
  Nil                 <*> _    = Nil
  (NonEmptyList f fs) <*> list = concat' (fmap f list) (fs <*> list)

instance Monad MyList where
  return = pure
  Nil                 >>= _ = Nil
  (NonEmptyList x xs) >>= f = concat' (f x) (xs >>= f)
```

The built-in `[]` instance is the same idea written more tersely: `return x = [x]` and `xs >>= f = concatMap f xs`.

### Examples

```haskell
triple :: a -> [a]
triple x = [x, x, x]
```

```
> ["Bunny"] >>= triple
["Bunny","Bunny","Bunny"]
> ["Bunny"] >>= triple >>= triple
["Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny","Bunny"]
```

Each `>>=` expands one element into many and flattens — exactly the behaviour you have seen as `flat_map` in Rust, `flatMap` in Scala, or `concatMap` in Haskell itself.

### Pythagorean Triples — Non-Deterministic Search

```haskell
pythTriples :: [(Int, Int, Int)]
pythTriples = do
  a <- [1..20]
  b <- [a..20]
  c <- [b..20]
  if a*a + b*b == c*c then return (a, b, c) else []
```

```
> pythTriples
[(3,4,5),(5,12,13),(6,8,10),(8,15,17),(9,12,15)]
```

Each `<-` picks one element from a list. The `if ... then return ... else []` is the standard non-deterministic *filter*: `return (a,b,c)` keeps the triple as a one-element list, `[]` discards it.

### The Same Idea in Other Languages

`(>>=)` for lists is `concatMap` — or `flat_map` as it is known almost everywhere. The Pythagorean triples example translates directly to Rust:

```rust
let triples: Vec<(i32, i32, i32)> =
    (1..=20).flat_map(|a|
        (a..=20).flat_map(move |b|
            (b..=20).filter(move |&c| a*a + b*b == c*c)
                    .map(move |c| (a, b, c))
    )).collect();
```

Each `flat_map` is `>>=` — expand one element into many, then flatten.

## Do Notation and List Comprehensions

Do notation for the list monad is closely related to list comprehensions. Fibonacci using do:

```haskell
fibDo :: [Integer]
fibDo = 0 : 1 : do
  (x, y) <- zip fibDo (tail fibDo)
  return (x + y)
```

The same thing using a list comprehension:

```haskell
fibComp :: [Integer]
fibComp = 0 : 1 : [ x + y | (x, y) <- zip fibComp (tail fibComp) ]
```

In general, list comprehensions are exactly do notation for `[]` with a more compact syntax. Guards in comprehensions correspond to the filter pattern from the previous section:

```haskell
[x | x <- [1..20], even x]
  ==
do { x <- [1..20]; if even x then [x] else [] }
```

## State Monad — Motivation

Imagine you are writing a compiler and need to generate unique variable names: `_t0`, `_t1`, `_t2`, … You need a counter that increases every time you use it. In Python or C++ you would just use a mutable variable. In Haskell every function is pure, so you have to pass the counter around by hand:

```haskell
freshNameManual :: Int -> (String, Int)
freshNameManual n = ("_t" ++ show n, n + 1)

twoNamesManual :: Int -> ((String, String), Int)
twoNamesManual n0 =
  let (name1, n1) = freshNameManual n0
      (name2, n2) = freshNameManual n1
  in  ((name1, name2), n2)
```

```
> twoNamesManual 0
(("_t0","_t1"), 2)
```

This works, but it is tedious and error-prone — it is easy to accidentally write `freshNameManual n0` twice instead of `freshNameManual n1`. The more steps you have, the worse it gets.

## State Monad — The Type

Look at the type of `freshNameManual` again:

```haskell
freshNameManual :: Int -> (String, Int)
--                 ^^^    ^^^^^^^^ ^^^
--                state    result  new state
```

Every stateful function has this shape: **old state in, result + new state out**. The State monad wraps exactly this pattern into a type:

```haskell
newtype State s a = State { runState :: s -> (a, s) }
```

- `s` — the type of the state (e.g. `Int` for our counter).
- `a` — the type of the result (e.g. `String` for the generated name).
- A `State s a` value is a *recipe*: "give me the current state, and I will give you back a result and the updated state."

`runState` unwraps the recipe and actually runs it.

## Exercise: Functor and Monad Instances for `State`

Working on a primed copy so we don't clash with the standard library:

```haskell
newtype State' s a = State' { runState' :: s -> (a, s) }
```

The `Functor` instance runs the state action, applies `f` to the result, and threads the new state through unchanged:

```haskell
instance Functor (State' s) where
  fmap f (State' g) = State' $ \s ->
    let (x, s') = g s
    in  (f x, s')
```

`Applicative` is needed before we can declare a `Monad` instance:

```haskell
instance Applicative (State' s) where
  pure x = State' (\s -> (x, s))
  liftA2 f (State' g) (State' h) = State' $ \s ->
    let (x, s')  = g s
        (y, s'') = h s'
    in  (f x y, s'')
```

And the `Monad` instance:

```haskell
instance Monad (State' s) where
  return = pure
  (State' g) >>= f = State' $ \s ->
    let (x, s')  = g s
        State' h = f x
    in  h s'
```

Read `>>=` carefully — it runs `g` on the current state, feeds the result `x` to `f`, then runs the resulting state action on the *updated* state `s'`. This is exactly the manual threading from before, done once and for all.

## Basic State Operations

Once we have the `Monad` instance, we can define convenient helpers. Think of the state as a mutable variable that you can read, write, or update:

```haskell
get :: State s s                    -- read the current value     (like x in C++)
get = State (\s -> (s, s))

put :: s -> State s ()              -- overwrite with a new value (like x = 5)
put s = State (\_ -> ((), s))

modify :: (s -> s) -> State s ()    -- apply a function           (like x += 1)
modify f = State (\s -> ((), f s))
```

These are the building blocks — most stateful code is written using `get`, `put`, and `modify` rather than constructing `State` values directly.

## The Fresh-Name Generator, Revisited

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
```

```
> runState twoNames 0
(("_t0","_t1"), 2)
```

Compare with the manual version: the body of `twoNames` no longer mentions the counter at all. The monad threads it for us.

### `fmap` is enough for some changes

We don't always need `(>>=)` — `fmap` is sometimes enough. `fmap` transforms the *result* of a stateful computation while the state still threads through automatically.

```haskell
freshNameUpper :: State Int String
freshNameUpper = fmap (map toUpper) freshName

freshLabel :: State Int String
freshLabel = fmap ("label_" ++) freshName

freshNameLen :: State Int Int
freshNameLen = fmap length freshName
```

```
> runState freshNameUpper 0       -- ("_T0", 1)
> runState freshLabel 7           -- ("label__t7", 8)
> runState freshNameLen 0         -- (3, 1)        -- "_t0" has length 3
> runState freshNameLen 100       -- (5, 101)      -- "_t100" has length 5
```

`fmap` can change the answer but cannot decide, *based on that answer*, whether or how to update the state — that extra power is exactly what `(>>=)` gives you over `fmap`.

## State Monad — Tracing the Execution

Let's see exactly how the monad threads the state behind the scenes. Consider:

```haskell
tick :: State Int Int        -- same shape as freshName, but returns the counter itself
tick = do
  n <- get
  put (n + 1)
  return n
```

Step-by-step trace of `runState (do { tick; tick; tick }) 0`:

```
                state    result
  start:          0
  1st tick:       0 → 1     0      -- get returns 0, put sets 1, return 0
  2nd tick:       1 → 2     1      -- get returns 1, put sets 2, return 1
  3rd tick:       2 → 3     2      -- get returns 2, put sets 3, return 2
  final:    result = 2, state = 3
```

Each `tick` reads the current counter, bumps it, and returns the old value — exactly like `counter++` in C++. The monad takes care of passing the updated counter from one `tick` to the next.

## State Monad — A Stack Example

A stack is just a list used as state:

```haskell
type Stack a = State [a]

push :: a -> Stack a ()
push x = modify (x:)

pop :: Stack a a
pop = do
  xs <- get
  case xs of
    (y:rest) -> do
      put rest
      return y
    []       -> error "pop: empty stack"
```

A small session:

```haskell
stackOps :: Stack Int Int
stackOps = do
  push 1
  push 2
  push 3
  _ <- pop       -- removes 3
  a <- pop       -- removes 2
  return a
```

```
> runState stackOps []
(2, [1])
```

Notice that the operations look just like imperative code, even though every function is pure — the `State` monad is doing the bookkeeping.
