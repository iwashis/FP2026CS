---
theme: ./lighttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 8


## Lecture code
Calculator/test/Spec.hs


## Reference
K. Claessen and J. Hughes, *QuickCheck: A Lightweight Tool for Random Testing of Haskell Programs*, ICFP 2000.

---

# Property-based testing in one slide

A unit test fixes one input and asserts one output:
```haskell
reverse [1,2,3] == [3,2,1]    -- passes or fails on this single example
```
A property fixes a **law** the function should obey for *every* input:
```haskell
prop_reverse_involutive :: [Int] -> Bool
prop_reverse_involutive xs = reverse (reverse xs) == xs
```
QuickCheck's job is to **generate random `xs`** and check the law. When it finds a counter-example, it **shrinks** it to the smallest input that still breaks the property.

Everything we will build today lives in `Test.QuickCheck`, but its core fits on a handful of slides — that is the whole point of the paper.

## The plan
1. The `Gen a` monad — random values of type `a`, parameterised by a *size*.
2. The `Arbitrary` class — every type ships its own generator (and shrinker).
3. The `Property` type — a generator of test outcomes.
4. The `Testable` class — turns functions into properties.
5. Conditional properties (`==>`), explicit generators (`forAll`), bookkeeping (`classify`, `collect`).
6. **Shrinking** — what makes counter-examples readable.
7. The check loop — how `quickCheck` actually runs.
8. A worked example: the `Calculator` test scaffold.

---

# The `Gen` monad

Two pieces of state are threaded through every generator:

1. a **size** `Int` — an upper bound on the "complexity" of the value (length of a list, depth of a tree, ...),
2. a **random seed** of type `StdGen`.

```haskell
import System.Random (StdGen, split, randomR)

newtype Gen a = Gen { unGen :: Int -> StdGen -> a }

instance Functor Gen where
  fmap f (Gen h) = Gen $ \n g -> f (h n g)

instance Applicative Gen where
  pure x = Gen $ \_ _ -> x
  Gen hf <*> Gen hx = Gen $ \n g ->
    let (g1, g2) = split g
    in  hf n g1 (hx n g2)

instance Monad Gen where
  return = pure
  Gen h >>= k = Gen $ \n g ->
    let (g1, g2) = split g
    in  unGen (k (h n g1)) n g2
```
A generator is *just* a function from `(size, seed)` to a value. `split` is the critical detail: two sub-generators must get **independent** seeds, otherwise children of a tree would correlate.

---

# Primitive generators

```haskell
choose :: (Int, Int) -> Gen Int
choose (lo, hi) = Gen $ \_ g -> fst (randomR (lo, hi) g)

sized :: (Int -> Gen a) -> Gen a
sized f = Gen $ \n g -> unGen (f n) n g

resize :: Int -> Gen a -> Gen a
resize m (Gen h) = Gen $ \_ g -> h m g

elements :: [a] -> Gen a
elements xs = do
  i <- choose (0, length xs - 1)
  pure (xs !! i)

oneof :: [Gen a] -> Gen a
oneof gs = do
  i <- choose (0, length gs - 1)
  gs !! i

frequency :: [(Int, Gen a)] -> Gen a
frequency wgs = do
  let total = sum (map fst wgs)
  k <- choose (1, total)
  pick k wgs
  where
    pick k ((w, g) : rest)
      | k <= w    = g
      | otherwise = pick (k - w) rest
    pick _ [] = error "frequency: empty list"

vectorOf :: Int -> Gen a -> Gen [a]
vectorOf 0 _ = pure []
vectorOf k g = (:) <$> g <*> vectorOf (k - 1) g
```

`sized` is how we **read** the budget; `resize` is how we **change** it; `frequency` is how we **bias** the choice (heavy leaves, light recursive cases).

---

# The `Arbitrary` class

```haskell
class Arbitrary a where
  arbitrary :: Gen a
  shrink    :: a -> [a]
  shrink _  = []                 -- default: no shrinks
```

Instances for primitives:
```haskell
instance Arbitrary Bool where
  arbitrary    = elements [False, True]
  shrink True  = [False]
  shrink False = []

instance Arbitrary Int where
  arbitrary = sized $ \n -> choose (-n, n)
  shrink 0  = []
  shrink n  = 0 : [ n `div` 2 | n /= 0 ]
                ++ [ n - 1   | n > 0 ]
                ++ [ n + 1   | n < 0 ]
```

Recursive instance for lists — *size-aware*:
```haskell
instance Arbitrary a => Arbitrary [a] where
  arbitrary = sized $ \n -> do
    k <- choose (0, n)
    vectorOf k arbitrary
  shrink []     = []
  shrink (x:xs) = xs                            -- drop the head
                : [ x':xs  | x'  <- shrink x  ] -- shrink the head
               ++ [ x:xs'  | xs' <- shrink xs ] -- shrink the tail
```

The size discipline is the **whole reason** `Gen` carries an `Int`: as we recurse into structure, we *shrink the budget* so generators terminate.

---

# Generators for user types — the recursion discipline

Take the calculator AST from Lecture 7:
```haskell
data Expr = Lit Int | Neg Expr | Add Expr Expr
          | Sub Expr Expr | Mul Expr Expr | Div Expr Expr
```
Naive generator:
```haskell
arbitrary = oneof
  [ Lit <$> arbitrary
  , Neg <$> arbitrary
  , Add <$> arbitrary <*> arbitrary, ... ]
```
loops with probability ≥ ½ — a binary node calls `arbitrary` twice and never shrinks the budget. The textbook fix:

```haskell
instance Arbitrary Expr where
  arbitrary = sized gen
    where
      gen 0 = Lit <$> arbitrary
      gen n = frequency
        [ (1, Lit <$> arbitrary)
        , (1, Neg <$> gen (n - 1))
        , (2, bin Add), (2, bin Sub)
        , (2, bin Mul), (2, bin Div) ]
        where
          half  = n `div` 2
          bin c = c <$> gen half <*> gen half

  shrink (Lit n)   = [ Lit n' | n' <- shrink n ]
  shrink (Neg e)   = e : [ Neg e' | e' <- shrink e ]
  shrink (Add a b) = [a, b]
                  ++ [ Add a' b | a' <- shrink a ]
                  ++ [ Add a b' | b' <- shrink b ]
  -- ... Sub, Mul, Div similar
```

Two invariants worth stressing:
- at `n = 0` only leaves are produced — recursion **must** terminate,
- binary constructors halve the budget — both children stay small.

---

# The `Property` type

A property is a generator of *test outcomes*:
```haskell
data Result = Result
  { ok     :: Maybe Bool   -- Nothing  = test discarded (precondition false)
                           -- Just b   = test passed / failed
  , reason :: String
  , inputs :: [String]     -- printable arguments collected during evaluation
  , labels :: [String]     -- bookkeeping (classify / collect)
  }

newtype Property = Property { unProperty :: Gen Result }
```
The two boolean carriers worth noticing:
- `ok = Nothing`     — *discarded*, not failed. `==>` uses this.
- `ok = Just False`  — the only state QuickCheck actually fails on.
- `ok = Just True`   — the test passed.

A `Property` is therefore richer than a `Bool`: it carries the inputs that produced the outcome, so the user gets a useful failure message.

---

# The `Testable` class — what counts as a property?

```haskell
class Testable prop where
  property :: prop -> Property

instance Testable Bool where
  property b = Property $ pure $ Result
    { ok = Just b, reason = "", inputs = [], labels = [] }

instance Testable Property where
  property p = p

instance (Arbitrary a, Show a, Testable prop)
      => Testable (a -> prop) where
  property f = Property $ do
    a   <- arbitrary
    res <- unProperty (property (f a))
    pure (res { inputs = show a : inputs res })
```

The recursive instance is the **whole story**: a curried function `a -> b -> Bool` is testable because `a -> b -> Bool` reduces to `b -> Bool` after randomly generating `a`, which reduces to `Bool` after randomly generating `b`. Each layer adds one random argument and records its `show` in the failure message.

---

# `==>`, `forAll`, `classify`, `collect`

Conditional properties — a discarded test counts neither as passed nor as failed:
```haskell
infixr 0 ==>
(==>) :: Testable prop => Bool -> prop -> Property
False ==> _ = Property $ pure $ Result
  { ok = Nothing, reason = "precondition false"
  , inputs = [], labels = [] }
True  ==> p = property p
```

Explicit generator (skips the `Arbitrary` default, useful for ranges or smart constructors):
```haskell
forAll :: (Show a, Testable prop) => Gen a -> (a -> prop) -> Property
forAll g k = Property $ do
  a   <- g
  res <- unProperty (property (k a))
  pure (res { inputs = show a : inputs res })
```

Bookkeeping — turns *did it pass?* into *how was the input distributed?*:
```haskell
classify :: Testable prop => Bool -> String -> prop -> Property
classify b lab p = Property $ do
  res <- unProperty (property p)
  pure (res { labels = if b then lab : labels res else labels res })

collect :: (Show a, Testable prop) => a -> prop -> Property
collect x = classify True (show x)
```

`classify` is invaluable for catching the "passes 100 times on the empty list" bug.

---

# Shrinking — what makes counter-examples readable

A counter-example is most useful when it is **minimal**. The shrinker is a greedy local-minimum search:
```haskell
shrinkLoop :: Testable prop
           => (a -> prop) -> (a -> [a]) -> a -> IO a
shrinkLoop run shrinkA = go
  where
    go x = do
      mfail <- firstFailing run (shrinkA x)
      case mfail of
        Nothing -> pure x                 -- local minimum reached
        Just x' -> go x'                  -- keep shrinking

firstFailing :: Testable prop
             => (a -> prop) -> [a] -> IO (Maybe a)
firstFailing _   []     = pure Nothing
firstFailing run (x:xs) = do
  passed <- runOnce (run x)
  if passed then firstFailing run xs else pure (Just x)
```
Read it like this:
- evaluate `shrink x` — a list of "slightly smaller" candidates,
- find the first one that *still* fails,
- iterate until no smaller failing candidate exists.

A bad shrinker is the difference between
```
*** Failed!   Add (Mul (Lit 27) (Neg (Lit 3))) (Sub (Lit 9) (Lit (-12)))
```
and
```
*** Failed!   Add (Lit 0) (Lit 0)
```

---

# Putting it together: `quickCheck`

```haskell
data Config = Config
  { maxSuccess :: Int    -- target number of passing tests
  , maxDiscard :: Int    -- give up after this many discards
  , maxSize    :: Int    -- cap on the size parameter
  }

defaultConfig :: Config
defaultConfig = Config 100 500 100

quickCheck :: Testable prop => prop -> IO ()
quickCheck = quickCheckWith defaultConfig

quickCheckWith :: Testable prop => Config -> prop -> IO ()
quickCheckWith cfg prop = do
  g0 <- newStdGen
  loop 0 0 g0
  where
    gen = unProperty (property prop)

    loop passed discarded g
      | passed    >= maxSuccess cfg =
          putStrLn $ "+++ OK, passed " ++ show passed ++ " tests."
      | discarded >= maxDiscard cfg =
          putStrLn $ "*** Gave up after " ++ show discarded ++ " discards."
      | otherwise = do
          let (g1, g2) = split g
              n        = passed `mod` maxSize cfg + 1
              res      = unGen gen n g1
          case ok res of
            Nothing    -> loop passed       (discarded + 1) g2
            Just True  -> loop (passed + 1) discarded       g2
            Just False -> putStrLn $
              "*** Failed! " ++ unwords (reverse (inputs res))
              -- shrink-then-print is what the real implementation does here
```

Three details worth noticing:
- `split` separates the per-test seed from the seed used for the *next* test — independence.
- The **size grows** with the test counter (``passed `mod` maxSize``) — small inputs first, larger ones later.
- Shrinking happens between `Just False` and the printout (omitted above for clarity — see the previous slide).

---

# A worked example: the Calculator

Recall the AST and evaluator from Lecture 7's calculator:
```haskell
data Expr = Lit Int | Neg Expr | Add Expr Expr
          | Sub Expr Expr | Mul Expr Expr | Div Expr Expr
eval :: Expr -> Maybe Int
```
Three honest properties:
```haskell
prop_pretty_parse_roundtrip :: Expr -> Property
prop_pretty_parse_roundtrip e =
  parseExpr (pretty e) === Just e

prop_add_commutative :: Expr -> Expr -> Property
prop_add_commutative a b =
  eval (Add a b) === eval (Add b a)

prop_sub_is_add_neg :: Expr -> Expr -> Property
prop_sub_is_add_neg a b =
  eval (Sub a b) === eval (Add a (Neg b))
```
`===` is QuickCheck's *equal-and-show-both-sides-on-failure* operator.

Two properties that look right but **must be guarded carefully**:
```haskell
prop_div_left_inverse :: Expr -> Expr -> Property
prop_div_left_inverse a b =
  eval b /= Just 0 ==> eval (Mul (Div a b) b) === eval a

prop_int_overflow :: Expr -> Expr -> Property
prop_int_overflow a b =
  classify (eval (Mul a b) == Nothing) "overflow" $
    eval (Mul a b) === eval (Mul b a)
```

---

# Three common pitfalls

1. **The generator is too narrow.** Always run `collect` or `classify` on a fresh property to see the input distribution. A property that passes 100 times on the empty list has not been tested.

2. **The shrinker is missing.** The default `shrink _ = []` produces unreadable counter-examples for recursive types — always write `shrink` for your own types.

3. **Conditional properties starve.** `xs /= [] ==> head xs == ...` discards half the tests on empty lists. If the discard rate is high, **use `forAll` with a non-empty generator** instead of `==>`.

These three rules cover ~90% of "my property passed but the bug is still there".

---

# What modern libraries change

The Claessen–Hughes paper is the entire core. Industrial libraries add:

1. **State-machine testing** (`Test.QuickCheck.Monadic`, `quickcheck-state-machine`) — generate sequences of API calls, shrink **the sequence**, not just the values.
2. **Integrated shrinking** (`hedgehog`) — generators and shrinkers share one Rose-tree representation, so you cannot accidentally have a clever generator and a useless shrinker.
3. **Generic derivation** (`generic-random`, `QuickCheck-GenericArbitrary`) — derive size-aware `Arbitrary` from a `Generic` instance.
4. **Coverage-guided generation** (`hedgehog`, `random-fu`) — track which code paths the random inputs hit and bias future tests towards uncovered branches.

But the *core* — `Gen`, `Arbitrary`, `Property`, `Testable`, shrinking — is exactly what we built today.

---

# Exercises

1. Implement the missing properties in `Calculator/test/Spec.hs`.

2. Write a size-aware `Arbitrary Expr` that **never** generates `Div _ (Lit 0)` directly — but still allows `Div` more generally. Hint: a smart constructor wrapped in `frequency`.

3. Replace `==>` in `prop_div_left_inverse` with a `forAll` over a generator of *non-zero* expressions. Compare the discard rate before and after.

4. Add a `classify` to `prop_pretty_parse_roundtrip` reporting whether the expression has depth `<= 3`, `<= 6`, or larger. Tune the generator until the buckets are roughly even.

5. Re-implement `quickCheck` end-to-end on top of the `Gen` / `Property` definitions in these slides, **but with the shrinker turned off**, and observe how unreadable counter-examples get.

6. (Hard.) Read `Test.QuickCheck.Monadic` and write a property that uses an `IORef` to test a small stateful container — e.g. a bounded queue.
