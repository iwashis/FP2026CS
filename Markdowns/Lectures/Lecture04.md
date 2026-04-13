# Applicative Functors & Monads

## Not Every Parameterised Type is a Functor

Recall the `Functor` type class:

```haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b
```

A functor lets you transform the value "inside" a context. But this only works when the type parameter appears in *output* (covariant) position.

Consider a predicate — a type that *consumes* an `a` rather than producing one:

```haskell
newtype Predicate a = Predicate (a -> Bool)

isEven :: Predicate Int
isEven = Predicate even
```

If we try to write `fmap` for `Predicate`:

```haskell
fmap :: (a -> b) -> Predicate a -> Predicate b
fmap f (Predicate p) = Predicate (\b -> ???)
```

We have `f :: a -> b` and `p :: a -> Bool`, and we need a `b -> Bool`. But we can only go from `a` to `b`, not from `b` to `a` — there is no way to feed `b` to `p`.

**Rule of thumb:** if the type parameter appears to the *left* of an arrow (input position), you cannot write a lawful `fmap`. Such types are called *contravariant*.

## Applicative Functors

Before we get to monads, we need to understand applicative functors — an important intermediate link in the type class hierarchy.

```haskell
class Functor f => Applicative f where
    pure  :: a -> f a
    (<*>) :: f (a -> b) -> f a -> f b
```

An applicative functor extends a regular functor with two operations:
- `pure` — places a value into a context (similar to `return` in monads)
- `(<*>)` — applies a function in a context to a value in a context

Applicative laws:
- **Identity**: `pure id <*> v = v`
- **Composition**: `pure (.) <*> u <*> v <*> w = u <*> (v <*> w)`
- **Homomorphism**: `pure f <*> pure x = pure (f x)`
- **Interchange**: `u <*> pure y = pure ($ y) <*> u`

### Maybe as Applicative

```haskell
data Maybe' a = Just' a | Nothing'
    deriving (Show, Functor)

instance Applicative Maybe' where
    pure = Just'
    Nothing'  <*> _         = Nothing'
    Just' f   <*> Nothing'  = Nothing'
    Just' f   <*> (Just' x) = Just' (f x)
```

If either side is `Nothing'`, the result is `Nothing'`. Otherwise we apply the function inside `Just'` to the value inside `Just'`:

```
> Just' (+3) <*> Just' 5
Just' 8
> Just' (*) <*> Just' 5 <*> Just' 3
Just' 15
> Nothing' <*> Just' 5
Nothing'
```

### Applicative in Practice: liftA2

The function `liftA2` lifts a binary function into an applicative context:

```haskell
liftA2 :: Applicative f => (a -> b -> c) -> f a -> f b -> f c
```

Suppose we have a `User` type and a constructor:

```haskell
data User = User String Int
    deriving (Show)

createUser :: String -> Int -> User
createUser = User
```

Without `liftA2`, creating a user from `Maybe` values requires manual case analysis:

```haskell
maybeCreate :: Maybe' String -> Maybe' Int -> Maybe' User
maybeCreate Nothing' _           = Nothing'
maybeCreate (Just' name) Nothing' = Nothing'
maybeCreate (Just' name) (Just' age) = Just' (User name age)
```

With `liftA2`, the same function becomes a one-liner:

```haskell
maybeCreate' :: Maybe' String -> Maybe' Int -> Maybe' User
maybeCreate' = liftA2 createUser
```

```
> maybeCreate' (Just' "Jan") (Just' 30)
Just' (User "Jan" 30)
> maybeCreate' Nothing' (Just' 30)
Nothing'
```

### Applicative Instance for Lists

```haskell
data MyList a = Nil | NonEmptyList a (MyList a)
    deriving (Show, Functor)

concat' :: MyList a -> MyList a -> MyList a
concat' Nil list = list
concat' (NonEmptyList x tail) list = NonEmptyList x (concat' tail list)

instance Applicative MyList where
    pure x = NonEmptyList x Nil
    Nil <*> _ = Nil
    (NonEmptyList f fs) <*> list = concat' (fmap f list) (fs <*> list)
```

The list applicative generates all combinations of functions and values. This is useful for generating test cases, board game moves, brute-force search, and more:

```haskell
sizes :: [String]
sizes = ["S", "M", "L"]

colors :: [String]
colors = ["red", "blue"]

allCombinations :: [(String, String)]
allCombinations = liftA2 (,) sizes colors
```

```
> liftA2 (,) sizes colors
[("S","red"),("S","blue"),("M","red"),("M","blue"),("L","red"),("L","blue")]
```

### A Functor That is Not Applicative

Not every functor can be made applicative. `Map k` from `Data.Map` is a functor — we can apply a function to every value with `Map.map`. But can we write `pure`?

```haskell
pure :: a -> Map k a
pure x = ???   -- a Map that maps *every possible key* to x?
```

A `Map` is finite, but the key space may be infinite (e.g. `Map Int a`). There is no way to build a map that contains *all* keys, so `pure` cannot be implemented.

**Lesson:** `pure` demands the ability to create a context from nothing. A finite `Map` cannot represent "a value everywhere", so it cannot be `Applicative`.

## Monads — The Problem First

Suppose we want to chain several operations that can each fail. Without any abstraction we get deeply nested case expressions:

```haskell
users :: Map.Map Int String
users = Map.fromList [(1, "alice"), (2, "bob")]

emails :: Map.Map String String
emails = Map.fromList [("alice", "alice@example.com")]

lookupEmailUgly :: Int -> Maybe String
lookupEmailUgly uid =
    case Map.lookup uid users of
        Nothing   -> Nothing
        Just name -> case Map.lookup name emails of
                       Nothing    -> Nothing
                       Just email -> Just email
```

Every step must manually check for failure. This does not scale.

## The Maybe Monad

The `Maybe` monad instance lets us chain fallible steps without manual case analysis:

```haskell
instance Monad Maybe' where
    Nothing'  >>= _ = Nothing'
    (Just' x) >>= f = f x
```

`(>>=)` (bind): if the left side is `Nothing'`, stop and return `Nothing'`; otherwise, feed the value inside `Just'` to the next step.

### Safe Division — Chaining Without Crashing

```haskell
safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv x y = Just (x `div` y)
```

```
> safeDiv 100 10 >>= safeDiv 5
Just 2
> safeDiv 100 0 >>= safeDiv 5
Nothing
```

### Dictionary Lookup Chain — Revisited

The ugly nested-case version from before becomes clean with `(>>=)`:

```haskell
lookupEmail :: Int -> Maybe String
lookupEmail uid = Map.lookup uid users >>= \name -> Map.lookup name emails
```

```
> lookupEmail 1
Just "alice@example.com"
> lookupEmail 2
Nothing
> lookupEmail 99
Nothing
```

### Safe Head and Tail

The standard `head` and `tail` functions in Haskell are partial — they crash on empty lists. We can make them safe by returning `Maybe`:

```haskell
head' :: [a] -> Maybe a
head' []    = Nothing
head' (x:_) = Just x

tail' :: [a] -> Maybe [a]
tail' []     = Nothing
tail' (_:xs) = Just xs
```

**Exercise:** using `head'` and `tail'`, write a function that returns the 3rd element of a list.

```
> third [1,2,3,4]
Just 3
> third [1,2]
Nothing
```

## Monads — The General Pattern

A monad is a functor `m` with two operations:

```haskell
class Applicative m => Monad m where
    (>>=)  :: m a -> (a -> m b) -> m b
    return :: a -> m a
```

Think of `m a` as "a computation that produces an `a`" — possibly with failure, non-determinism, I/O, etc.

Monad laws:
- **Left identity**: `return x >>= f = f x`
- **Right identity**: `m >>= return = m`
- **Associativity**: `(m >>= f) >>= g = m >>= (\x -> f x >>= g)`

### Composing Monadic Functions

A monadic function has type `a -> m b`. Two such functions can be composed with the fish operator:

```haskell
(>=>) :: Monad m => (a -> m b) -> (b -> m c) -> a -> m c
f >=> g = \x -> f x >>= g
```

The ugly `lookupEmailUgly` rewritten with `(>=>)`:

```haskell
lookupNice :: Int -> Maybe String
lookupNice x = ((\uid -> Map.lookup uid users) >=> (\name -> Map.lookup name emails)) x
```

## Do Notation

Chaining many `(>>=)` calls with lambdas gets noisy. Haskell provides do notation as syntactic sugar.

With `(>>=)`:

```haskell
lookupEmail' :: Int -> Maybe String
lookupEmail' uid =
    Map.lookup uid users >>= \name ->
    Map.lookup name emails
```

With do notation:

```haskell
lookupEmailDo :: Int -> Maybe String
lookupEmailDo uid = do
    name  <- Map.lookup uid users
    email <- Map.lookup name emails
    return email
```

Each `x <- action` is just `action >>= \x -> ...` in disguise. The compiler desugars do notation into `(>>=)` chains automatically.

Do notation desugaring rules:

```
do { x <- m ; rest }  =  m >>= \x -> do { rest }
do { m ; rest }        =  m >>  do { rest }
do { return x }        =  return x
```

`(>>)` is just `(>>=)` that discards the result:

```haskell
(>>) :: Monad m => m a -> m b -> m b
m >> k = m >>= \_ -> k
```
