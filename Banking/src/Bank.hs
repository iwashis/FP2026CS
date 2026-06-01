-- | A tiny in-memory bank built on Software Transactional Memory (STM).
--
-- The whole point of this module is teaching:
--
--   * An 'Account' is just a mutable cell ('TVar') holding a balance.
--   * Every operation that touches money returns an @STM@ action, /not/ @IO@.
--     An @STM@ action is a description of a transaction; nothing happens until
--     you hand it to 'atomically'. Inside one 'atomically' block the runtime
--     guarantees the changes are applied all-or-nothing and in isolation, even
--     when dozens of threads run concurrently.
--   * Because @STM@ actions are ordinary values, we can /compose/ them: a
--     'transfer' is literally a 'withdraw' followed by a 'deposit', and the two
--     together still happen atomically. Try doing that with locks!
--
-- Read the operations top to bottom: each one introduces one new STM idea
-- (read/write, 'retry'/'check', 'orElse').
module Bank
  ( -- * Types
    Money
  , AccountId
  , Account (accountId)
  , Bank (bankAccounts)
    -- * Construction
  , newAccount
  , newBank
    -- * Reading
  , balance
  , totalFunds
    -- * Single-account operations
  , deposit
  , withdraw
  , withdrawWhenReady
    -- * Composed, multi-account operations
  , transfer
  , tryTransfer
  , transferFromAny
  ) where

import Control.Concurrent.STM
import Control.Monad (forM)

-- | Money is whole units (think cents). 'Integer' so we never overflow during
-- a stress test and the arithmetic is exact.
type Money = Integer

-- | A human-friendly account number.
type AccountId = Int

-- | An account is an identifier plus a transactional cell holding the balance.
-- The balance lives in a 'TVar' so it can be read and written inside @STM@.
data Account = Account
  { accountId      :: !AccountId
  , accountBalance :: !(TVar Money)
  }

-- | A bank is just the accounts it manages.
newtype Bank = Bank
  { bankAccounts :: [Account]
  }

-- | Create a fresh account. This is an @STM@ action so it can be combined with
-- other account creations into a single transaction (see 'newBank').
newAccount :: AccountId -> Money -> STM Account
newAccount aid initial = Account aid <$> newTVar initial

-- | Open a bank with @n@ accounts (numbered @1..n@), each starting with the
-- same balance. All accounts are created in one atomic step.
newBank :: Int -> Money -> IO Bank
newBank n initial =
  atomically $ Bank <$> forM [1 .. n] (`newAccount` initial)

-- | Read one account's balance.
balance :: Account -> STM Money
balance = readTVar . accountBalance

-- | Sum every account in a /single consistent snapshot/.
--
-- This is the killer demo for isolation: no matter how many transfers are in
-- flight on other threads, 'totalFunds' can never observe a half-finished
-- transfer (money debited from one account but not yet credited to the other).
-- The transaction sees one coherent version of the whole bank.
totalFunds :: Bank -> STM Money
totalFunds (Bank accs) = sum <$> mapM balance accs

-- | Add money. Reads the current balance and writes the new one; because this
-- runs inside a transaction the read-modify-write cannot be interleaved with
-- anyone else's.
deposit :: Account -> Money -> STM ()
deposit acc amount = modifyTVar' (accountBalance acc) (+ amount)

-- | Remove money, but only if there is enough.
--
-- 'check' is the heart of the example: if the predicate is 'False' the
-- transaction calls 'retry', which /blocks/ the thread and parks it until one
-- of the @TVar@s it has read changes — then STM automatically re-runs the
-- whole transaction. No condition variables, no manual signalling.
withdraw :: Account -> Money -> STM ()
withdraw acc amount = do
  bal <- balance acc
  check (bal >= amount)            -- if not enough: retry (block) until it is
  writeTVar (accountBalance acc) (bal - amount)

-- | Alias that names the blocking behaviour explicitly, for the lecture slides.
withdrawWhenReady :: Account -> Money -> STM ()
withdrawWhenReady = withdraw

-- | Move money between accounts atomically.
--
-- Note how this is just two smaller @STM@ actions glued together with @>>@.
-- The result is /still/ one transaction: an observer either sees neither the
-- debit nor the credit, or both. If @from@ lacks the funds the embedded
-- 'withdraw' blocks the whole transfer until they arrive.
transfer :: Account -> Account -> Money -> STM ()
transfer from to amount = do
  withdraw from amount
  deposit to amount

-- | Non-blocking transfer. 'orElse' runs its left action; if that action would
-- 'retry' (here: insufficient funds), 'orElse' abandons it with no effect and
-- runs the right one instead. So we turn "block until funded" into "tell me it
-- failed" without changing 'transfer' at all.
tryTransfer :: Account -> Account -> Money -> STM Bool
tryTransfer from to amount =
  (transfer from to amount >> pure True) `orElse` pure False

-- | Pay @to@ by pulling the money from the /first/ of @sources@ that can
-- currently cover it. We fold the candidate transfers together with 'orElse';
-- the final 'retry' means "if none can pay right now, block until one can".
transferFromAny :: [Account] -> Account -> Money -> STM ()
transferFromAny sources to amount =
  foldr orElse retry [ transfer s to amount | s <- sources ]
