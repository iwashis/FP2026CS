# Homework 04

## The Reader Monad

```haskell
newtype Reader r a = Reader { runReader :: r -> a }
-- ^ runReader executes a Reader computation by supplying an environment `r`
--   and returning a result of type `a`.
```

The `Reader` monad represents computations that can read values from a shared environment.
It is essentially a wrapper around a function `r -> a`, where `r` is the (read-only)
environment threaded implicitly through the computation.

> **Note:** you must implement `Reader` from scratch — do **not** import it from
> `Control.Monad.Reader`. The goal of this homework is to understand how the monad
> works under the hood.

1. **Functor, Applicative, and Monad instances**

   Implement the three standard instances for `Reader r`:
   ```haskell
   instance Functor (Reader r) where
     -- fmap :: (a -> b) -> Reader r a -> Reader r b
     fmap = undefined

   instance Applicative (Reader r) where
     -- pure   :: a -> Reader r a
     pure   = undefined
     -- liftA2 :: (a -> b -> c) -> Reader r a -> Reader r b -> Reader r c
     liftA2 = undefined

   instance Monad (Reader r) where
     -- (>>=) :: Reader r a -> (a -> Reader r b) -> Reader r b
     (>>=) = undefined
   ```
   The intended semantics are the usual ones: `fmap f r` runs `r` in the environment
   and then applies `f` to the result; `pure x` ignores the environment and returns `x`;
   `liftA2 f ra rb` runs both `ra` and `rb` in the same environment and combines their
   results with the binary function `f`; `(>>=)` sequences two `Reader` computations,
   passing the same environment to both and letting the second depend on the value
   produced by the first.

2. **Primitive operations**

   Implement the basic `Reader` primitives — these are the only "public" interface you
   should need to write the rest of the code; once they are in place, prefer them (and
   `do`-notation) over pattern-matching on the `Reader` constructor directly.
   ```haskell
   -- Retrieves the entire environment.
   ask   :: Reader r r

   -- Retrieves a value derived from the environment by applying a projection,
   -- e.g. `asks interestRate :: Reader BankConfig Double`.
   asks  :: (r -> a) -> Reader r a

   -- Runs a subcomputation in a locally modified environment. The modification
   -- is only visible inside the passed Reader — once it returns, the outer
   -- environment is restored (conceptually; there is no mutable state, the
   -- modified environment simply goes out of scope).
   local :: (r -> r) -> Reader r a -> Reader r a
   ```

3. **A practical example — banking system**

   Consider a small banking system where the bank's configuration (interest rate,
   fees, limits) is the read-only environment shared by every operation:
   ```haskell
   data BankConfig = BankConfig
     { interestRate   :: Double  -- annual interest rate (e.g. 0.05 for 5%)
     , transactionFee :: Int     -- flat fee charged per transaction
     , minimumBalance :: Int     -- minimum required balance on an account
     } deriving (Show)

   data Account = Account
     { accountId :: String       -- account identifier
     , balance   :: Int          -- current balance
     } deriving (Show)
   ```
   Implement the following four functions using the `Reader` monad. Prefer `ask` / `asks`
   and `do`-notation over pattern-matching on the `Reader` constructor — this is what
   makes the monadic style pay off:
   ```haskell
   -- Computes the interest accrued on the account, based on the configured rate.
   -- The result should be an Int — round or truncate as you see fit, but be consistent.
   calculateInterest   :: Account -> Reader BankConfig Int

   -- Deducts the transaction fee from the account and returns the updated account.
   -- The accountId should remain unchanged.
   applyTransactionFee :: Account -> Reader BankConfig Account

   -- Checks whether the account balance meets the configured minimum.
   checkMinimumBalance :: Account -> Reader BankConfig Bool

   -- Runs the three operations above on a single account and combines their results.
   -- The returned tuple contains:
   --   * the account after the transaction fee has been applied,
   --   * the interest computed from the ORIGINAL account,
   --   * whether the ORIGINAL account meets the minimum balance requirement.
   processAccount      :: Account -> Reader BankConfig (Account, Int, Bool)
   ```
   Once everything is implemented, the following should work in GHCi:
   ```haskell
   ghci> let cfg = BankConfig { interestRate = 0.05, transactionFee = 2, minimumBalance = 100 }
   ghci> let acc = Account { accountId = "A-001", balance = 1000 }
   ghci> runReader (processAccount acc) cfg
   (Account {accountId = "A-001", balance = 998}, 50, True)
   ```
