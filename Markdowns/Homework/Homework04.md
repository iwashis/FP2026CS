# Homework 04

## Definition

```haskell
newtype Reader r a = Reader { runReader :: r -> a }
-- ^ runReader executes a Reader computation by supplying an environment `r`
--   and returning a result of type `a`.
```

The `Reader` monad represents computations that can read values from a shared
environment. It is essentially a wrapper around a function `r -> a`, where `r`
is the (read-only) environment threaded implicitly through the computation.

> **Note:** You must implement `Reader` from scratch — do **not** import it
> from `Control.Monad.Reader`. The goal of this homework is to understand how
> the monad works under the hood.

## Task 1: Basic instances (4 points)

Implement the following instances for the `Reader` monad:

```haskell
instance Functor (Reader r) where
  -- fmap :: (a -> b) -> Reader r a -> Reader r b
  fmap = undefined
  -- Transforms the result of a Reader while keeping access to the environment.
  -- Intuition: fmap f r = "run r in the environment, then apply f to the result".
```

```haskell
instance Applicative (Reader r) where
  -- pure :: a -> Reader r a
  pure = undefined
  -- Wraps a value into a Reader that ignores the environment and just returns it.

  -- (<*>) :: Reader r (a -> b) -> Reader r a -> Reader r b
  (<*>) = undefined
  -- Runs both computations in the same environment, then applies the first
  -- result (a function) to the second result (its argument).
```

```haskell
instance Monad (Reader r) where
  -- (>>=) :: Reader r a -> (a -> Reader r b) -> Reader r b
  (>>=) = undefined
  -- Sequences two Reader computations, passing the same environment to both.
  -- The second computation may depend on the value produced by the first.
```


## Task 2: Primitive operations (3 points)

Implement the basic Reader primitives. These functions are the only "public"
interface you will need to write the rest of the code — once you have them,
you should prefer them (and `do`-notation) over raw `Reader` constructors.

```haskell
-- Retrieves the entire environment.
ask :: Reader r r
ask = undefined

-- Retrieves a value derived from the environment by applying a projection.
-- Example: asks interestRate :: Reader BankConfig Double
asks :: (r -> a) -> Reader r a
asks = undefined

-- Runs a subcomputation in a locally modified environment.
-- The modification is only visible inside the passed Reader — once it
-- returns, the outer environment is restored (conceptually — there is no
-- mutable state, the modified environment simply goes out of scope).
local :: (r -> r) -> Reader r a -> Reader r a
local = undefined
```

## Task 3: A practical example — banking system (3 points)

Below are the data structures for a practical use case of the `Reader` monad:
a small banking system where the bank's configuration (interest rate, fees,
limits) is the read-only environment shared by every operation.

```haskell
-- Configuration of the banking application.
data BankConfig = BankConfig
  { interestRate   :: Double  -- annual interest rate (e.g. 0.05 for 5%)
  , transactionFee :: Int     -- flat fee charged per transaction
  , minimumBalance :: Int     -- minimum required balance on an account
  } deriving (Show)

-- A bank account.
data Account = Account
  { accountId :: String  -- account identifier
  , balance   :: Int     -- current balance
  } deriving (Show)
```

Implement the following functions using the `Reader` monad. Try to use
`ask` / `asks` (and `do`-notation) rather than pattern-matching on the
`Reader` constructor directly — this is what makes the monadic style pay off.

```haskell
-- Computes the interest accrued on the account, based on the configured rate.
-- The result should be an Int — round/truncate as you see fit, but be
-- consistent.
calculateInterest :: Account -> Reader BankConfig Int
calculateInterest = undefined

-- Deducts the transaction fee from the account and returns the updated account.
-- The accountId should remain unchanged.
applyTransactionFee :: Account -> Reader BankConfig Account
applyTransactionFee = undefined

-- Checks whether the account balance meets the configured minimum.
checkMinimumBalance :: Account -> Reader BankConfig Bool
checkMinimumBalance = undefined

-- Runs the three operations above on a single account and combines their
-- results. The returned tuple contains:
--   * the account after the transaction fee has been applied,
--   * the interest computed from the ORIGINAL account,
--   * whether the ORIGINAL account meets the minimum balance requirement.
-- Prefer `do`-notation here — this is the function that demonstrates why
-- Reader is convenient: the configuration is threaded implicitly.
processAccount :: Account -> Reader BankConfig (Account, Int, Bool)
processAccount = undefined
```

### Example session

Once everything is implemented, the following should work in GHCi:

```haskell
ghci> let cfg = BankConfig { interestRate = 0.05, transactionFee = 2, minimumBalance = 100 }
ghci> let acc = Account { accountId = "A-001", balance = 1000 }
ghci> runReader (processAccount acc) cfg
(Account {accountId = "A-001", balance = 998}, 50, True)
```
