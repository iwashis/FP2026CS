---
theme: ./defaulttheme.json
author: Tomasz Brengos
date: MMMM dd, YYYY
---



# Functional Programming

## Tomasz Brengos

Lecture 9


## Lecture code
Banking/src/Bank.hs, Banking/app/Main.hs


## Reference
T. Harris, S. Marlow, S. Peyton Jones and M. Herlihy, *Composable Memory Transactions*, PPoPP 2005.

---

# Mutable state in `IO`: `IORef`

Haskell values don't change. For a counter / cache / cursor we need a mutable cell, and it has to live in `IO`.

```haskell
import Data.IORef

data IORef a

newIORef    :: a -> IO (IORef a)
readIORef   :: IORef a -> IO a
writeIORef  :: IORef a -> a -> IO ()
modifyIORef :: IORef a -> (a -> a) -> IO ()
```

Sequential use:
```haskell
demo = do
  ref <- newIORef (0 :: Int)
  writeIORef  ref 10
  modifyIORef ref (+ 1)         -- 10 -> 11
  readIORef ref >>= print       -- 11
```

`IORef a` is a single mutable variable. Every read and write is in `IO` — no hidden state.

Key fact for today: `modifyIORef ref f` is **not atomic**. It is `readIORef ref >>= writeIORef ref . f`. Two steps. Anything can happen between them.

---

# Threads: `forkIO`

Cheap user-space threads. The primitive:
```haskell
import Control.Concurrent

forkIO       :: IO () -> IO ThreadId
threadDelay  :: Int -> IO ()           -- microseconds
myThreadId   :: IO ThreadId
killThread   :: ThreadId -> IO ()
```

```haskell
main = do
  _ <- forkIO $ do threadDelay 200000; putStrLn "child"
  putStrLn "parent"
  threadDelay 500000                   -- without this, main exits and kills the child
```

Two things to notice:
- `forkIO` returns immediately — the new thread runs the action *concurrently*.
- When `main` returns, the runtime exits and *all* threads die. Hence the trailing `threadDelay`. In real code you wait on a synchronisation primitive instead — next slide.

For real parallelism: compile `-threaded`, run with `+RTS -N`. Banking does both (`package.yaml`), so threads land on different cores.

---

# Synchronisation: `MVar`

The classic concurrency primitive: a one-slot box that is either full or empty.

```haskell
import Control.Concurrent.MVar

data MVar a

newEmptyMVar :: IO (MVar a)
newMVar      :: a -> IO (MVar a)
takeMVar     :: MVar a -> IO a         -- blocks if empty,  empties on take
putMVar      :: MVar a -> a -> IO ()   -- blocks if full,   fills on put
readMVar     :: MVar a -> IO a         -- blocks if empty,  leaves it full
modifyMVar_  :: MVar a -> (a -> IO a) -> IO ()
withMVar     :: MVar a -> (a -> IO b) -> IO b
```

Two uses on one type:

```haskell
-- (a) a one-shot signal: wait for a child to finish.
done <- newEmptyMVar
_    <- forkIO $ do work; putMVar done ()
takeMVar done                          -- blocks until the child posts

-- (b) a lock around shared state.
ctr <- newMVar (0 :: Int)
modifyMVar_ ctr (\n -> pure (n + 1))   -- atomic increment
```

`MVar` is honest about what it is: a blocking queue of size one. It composes badly with itself — `withMVar a $ \_ -> withMVar b $ ...` on two threads in opposite order is a deadlock. We will come back to this.

---

# `async`: `forkIO` done right

`forkIO` gives you no result and no exception handling. `async` fixes both.

```haskell
import Control.Concurrent.Async

data Async a

async                   :: IO a -> IO (Async a)     -- start, get handle
wait                    :: Async a -> IO a          -- block for the result
waitCatch               :: Async a -> IO (Either SomeException a)
cancel                  :: Async a -> IO ()

concurrently            :: IO a -> IO b -> IO (a, b)         -- both, in parallel
race                    :: IO a -> IO b -> IO (Either a b)   -- first to finish wins

mapConcurrently         :: Traversable t => (a -> IO b) -> t a -> IO (t b)
mapConcurrently_        :: Foldable t    => (a -> IO b) -> t a -> IO ()
replicateConcurrently_  :: Int -> IO a -> IO ()
```

```haskell
main = do
  (a, b) <- concurrently (heavyA) (heavyB)
  print (a + b)

main = mapConcurrently_ print [1 .. 5 :: Int]      -- order unspecified
```

Three guarantees `forkIO` doesn't give:
- the parent gets the child's return value (or exception);
- if the parent dies, the children are cancelled;
- structured concurrency: `mapConcurrently_` returns only when *all* tasks have finished.

Every parallel block in `Banking/app/Main.hs` uses `mapConcurrently_` or `replicateConcurrently_`.

Next question: what happens when two threads touch the same `IORef`?

---

# The race

100 threads, 1000 increments each. Expected: 100000. Actual: smaller, different every run.

```haskell
mapConcurrently_
  (\_ -> replicateM_ 1000 (modifyIORef ref (+ 1)))
  [1 .. 100]

-- expected 100000, got 96243   (lost 3757)
```

Why: `modifyIORef` is read-then-write. Two threads read the same old value, both write `old + 1`. One increment vanishes.

Locks (`MVar`, `withMVar`) fix it for one counter. They do *not* compose — glue two correct lock-based functions together and you get deadlocks. Lock ordering is what ages programmers.

---

# STM in one slide

```haskell
import Control.Concurrent.STM

tv <- newTVarIO (0 :: Int)
atomically (modifyTVar' tv (+ 1))   -- always exact
```

- `TVar a` — transactional cell. Only touchable inside `STM`.
- `STM a` — description of a transaction. No `IO`. Doesn't run until `atomically`.
- `atomically :: STM a -> IO a` — runs it once, all-or-nothing, isolated from every other `atomically`.

`retry`, `orElse`, `check`, `transfer` — all just compositions of `STM` actions. Transactions as first-class values is the Harris et al. point.

---

# The `STM` monad and `TVar`

```haskell
data STM a
instance Monad STM

data TVar a

newTVar     :: a -> STM (TVar a)
readTVar    :: TVar a -> STM a
writeTVar   :: TVar a -> a -> STM ()
modifyTVar  :: TVar a -> (a -> a) -> STM ()    -- non-strict
modifyTVar' :: TVar a -> (a -> a) -> STM ()    -- strict
```

Bridge to `IO`:
```haskell
atomically :: STM a -> IO a
newTVarIO  :: a -> IO (TVar a)
readTVarIO :: TVar a -> IO a
```

## Why no `IO` inside `STM`?

The runtime re-runs transactions (on conflict) and abandons them (on `retry`, lost `orElse`). `launchMissiles` inside `STM` would be unsound. There is no `liftIO :: IO a -> STM a`. By design.

---

# The bank

From `Banking/src/Bank.hs`:

```haskell
type Money     = Integer
type AccountId = Int

data Account = Account
  { accountId      :: !AccountId
  , accountBalance :: !(TVar Money)
  }

newtype Bank = Bank { bankAccounts :: [Account] }

newAccount :: AccountId -> Money -> STM Account
newAccount aid initial = Account aid <$> newTVar initial

newBank :: Int -> Money -> IO Bank
newBank n initial =
  atomically $ Bank <$> forM [1 .. n] (`newAccount` initial)
```

- `newAccount :: ... -> STM Account` — so `newBank` opens `n` accounts in one transaction. All or none.
- `Account` itself is immutable; only the `TVar` inside is mutable. Safe to share between threads.

---

# Reading: `balance`, `totalFunds`

```haskell
balance :: Account -> STM Money
balance = readTVar . accountBalance

totalFunds :: Bank -> STM Money
totalFunds (Bank accs) = sum <$> mapM balance accs
```

`totalFunds` reads dozens of `TVar`s. With locks, two bad options:
- lock the whole bank — no concurrency;
- read without locks — observe money mid-transfer (debited, not credited).

STM: just `atomically`. One consistent snapshot, or the transaction re-runs. No half-finished transfers ever observed.

---

# Writing: `deposit`

```haskell
deposit :: Account -> Money -> STM ()
deposit acc amount = modifyTVar' (accountBalance acc) (+ amount)
```

Long form:
```haskell
deposit acc amount = do
  bal <- readTVar (accountBalance acc)
  writeTVar (accountBalance acc) (bal + amount)
```

Same read-then-write that broke with `IORef`. Why is it OK now?

Inside one `STM`, `atomically` either commits both reads/writes or aborts and re-runs on a fresh snapshot. And `deposit :: STM ()` — the compiler won't let you skip `atomically`.

## Act 2, one line
```haskell
atomically (modifyTVar' tv (+ 1))   -- always 100000
```

---

# Blocking: `retry`, `check`

`withdraw` has a precondition: enough money. First attempt:

```haskell
withdrawV1 :: Account -> Money -> STM Bool
withdrawV1 acc amount = do
  bal <- balance acc
  if bal < amount
    then pure False
    else do writeTVar (accountBalance acc) (bal - amount); pure True
```

Works, but pushes "what now?" onto the caller — usually a polling loop. Better:

```haskell
withdraw :: Account -> Money -> STM ()
withdraw acc amount = do
  bal <- balance acc
  check (bal >= amount)            -- if False: retry
  writeTVar (accountBalance acc) (bal - amount)
```

```haskell
retry :: STM a
check :: Bool -> STM ()
check b = if b then pure () else retry
```

`retry` = "abandon this attempt". The runtime parks the thread and wakes it only when one of the `TVar`s the transaction *read* changes. Then re-runs.

So `withdraw` on an empty account doesn't spin. It sleeps until somebody deposits.

---

# `retry` is not a loop — it's "wake me when"

Misreading: `retry` immediately re-runs. It doesn't.

The runtime keeps the **read set** of each blocked transaction. As long as those `TVar`s are unchanged, re-running gives the same result. Pointless. The thread stays parked.

This is the point of STM over locks: the wake condition is *derived* from the read set. No
```haskell
takeMVar balanceChangedSignal
```
and no `signal` to remember on every code path.

## Act 3
```text
[teller] trying to withdraw 100 from an empty account...
[boss]   account is empty, teller is parked (not spinning).
[boss]   depositing 250...
[teller] withdrawal completed; balance now 150
```

`deposit acc 250` writes `accountBalance acc`. That's in the parked transaction's read set → wake → re-run → `check` passes.

---

# Composition: `transfer` = `withdraw` + `deposit`

```haskell
transfer :: Account -> Account -> Money -> STM ()
transfer from to amount = do
  withdraw from amount
  deposit  to   amount
```

Two `STM` actions sequenced with `>>`. Still one transaction. Observers see both effects or neither. If `from` is short, the inner `check` retries — the whole transfer is parked until `from` is funded.

## Same thing with two `MVar`s
```haskell
withMVar fromLock $ \_ -> withMVar toLock $ \_ -> ...
```

Deadlocks the first time `transfer a b` and `transfer b a` run on different threads. Fix: order locks by account id, in every function, forever. STM: no locks to order.

---

# Choice: `orElse`

`retry` blocks. Sometimes you want "if it would block, try something else":

```haskell
orElse :: STM a -> STM a -> STM a
```

`p `orElse` q`:
- run `p`;
- `p` commits → that's the result;
- `p` calls `retry` → roll back its effects, run `q` from the original snapshot;
- both `retry` → the whole `orElse` retries.

```haskell
-- Non-blocking: turn "block until funded" into Bool.
tryTransfer :: Account -> Account -> Money -> STM Bool
tryTransfer from to amount =
  (transfer from to amount >> pure True) `orElse` pure False

-- Pay from the first source that can cover it; block if none can.
transferFromAny :: [Account] -> Account -> Money -> STM ()
transferFromAny sources to amount =
  foldr orElse retry [ transfer s to amount | s <- sources ]
```

`transferFromAny` is a one-liner. With locks it's a chapter.

---

# Act 4

```text
tryTransfer A->C 100 (A has 30):  False
tryTransfer B->C 100 (B has 200): True
transferFromAny [A,B] -> C 80: took it from the first able account
  account 1 balance: 30          -- A: untouched
  account 2 balance: 20          -- B: 200 - 100 - 80
  account 3 balance: 180         -- C: 100 + 80
```

Common idioms, as combinators:

| Pattern                              | Expression                                |
|--------------------------------------|-------------------------------------------|
| "do `p`, or report failure"          | `(p >> pure True) \`orElse\` pure False`  |
| "first of `ps` that commits now"     | `foldr orElse retry ps`                   |
| "first of `ps`, otherwise block"     | `foldr1 orElse ps`                        |
| "all of these atomically"            | `sequence_ ps`                            |

One line each. No race to chase.

---

# How the runtime works

Not needed to *use* STM, but useful for cost.

1. **Optimistic execution.** `atomically m` runs `m` without locks. Reads → thread-local *read log*; writes → *write log*. Real `TVar`s untouched.
2. **Commit.** Briefly lock the touched `TVar`s, verify every read-log value still matches, flush the write log. Atomic from outside.
3. **Conflict.** Any mismatch → abort, re-run with a fresh log. Code is pure, so re-running is safe.
4. **`retry`.** Read log becomes the wake-set. Park the thread on those `TVar`s.
5. **`orElse`.** Nested logs. Rolling back is throwing the inner log away.

Consequences:
- Short transactions, few `TVar`s → basically free.
- Long transaction + hot `TVar` → starvation. Keep them small.
- No `IO` in `STM` → re-execution never observable.

---

# Worked example: Act 5

200 workers × 500 random transfers × 50 accounts. From `app/Main.hs`:

```haskell
act5_parallelStressTest = do
  bank   <- newBank 50 1000
  before <- atomically (totalFunds bank)
  let accs = bankAccounts bank
  mapConcurrently_ (const (worker accs 500)) [1 .. 200]
  after  <- atomically (totalFunds bank)
  print (before == after)            -- always True

worker accs n = replicateM_ n $ do
  i      <- randomRIO (0, length accs - 1)
  j      <- randomRIO (0, length accs - 1)
  amount <- randomRIO (1, 50)
  when (i /= j) $
    void (atomically (tryTransfer (accs !! i) (accs !! j) amount))
```

Two invariants STM gives you for free:
1. `before == after` — every transfer is one transaction; the sum cannot change.
2. `minimum bals >= 0` — `check (bal >= amount)` in `withdraw`. `tryTransfer` falls through to `False` so workers don't block.

```text
total after: 50000
CONSERVED: not a single cent created or destroyed. STM works.
min balance across accounts: 0 (never negative)
```

---

# Tests as specs

`Banking/test/Spec.hs`:

```haskell
testConservation = do
  bank <- newBank 30 500
  before <- atomically (totalFunds bank)
  let accs = bankAccounts bank
  mapConcurrently_ (const (randomWork accs 400)) [1 .. 100]
  after <- atomically (totalFunds bank)
  pure (before == after)

testNoNegative = do
  bank <- newBank 20 100
  let accs = bankAccounts bank
  mapConcurrently_ (const (randomWork accs 500)) [1 .. 80]
  bals <- forM accs (atomically . balance)
  pure (minimum bals >= 0)
```

With locks these tests are flaky — pass locally, fail in CI. Under STM the invariants belong to the abstraction, not the schedule. Always pass.

`cd Banking && stack test`.

---

# What STM does *not* solve

1. **No `IO` inside `STM`.** Logging a transfer to disk goes *outside* `atomically`:
   ```haskell
   action <- atomically $ do { transfer a b 100; pure (LogTransfer a b 100) }
   logToDisk action
   ```
2. **Cost grows with size.** Many `TVar`s read → more log validation, more conflicts. Prefer many small transactions to one giant one.
3. **No fairness guarantee.** A transaction that keeps losing to a busier neighbour can starve. Real runtimes back off; we ignore it.

None of these break composition. Two correct `STM` actions compose to a correct `STM` action (sequencing, `orElse`, `<|>`). Locks don't.

---

# Summary

| Primitive                  | Meaning                                                  |
|----------------------------|----------------------------------------------------------|
| `STM a`                    | a transaction producing an `a`                           |
| `TVar a`                   | a transactional cell                                     |
| `atomically`               | run a transaction, all-or-nothing                        |
| `readTVar`, `writeTVar`    | the only way to touch a `TVar`                           |
| `retry`                    | "park me on what I read"                                 |
| `check b`                  | `retry` when `b` is `False`                              |
| `orElse`                   | "try this; if it would `retry`, try the other"           |

Three properties:
1. **Atomicity** — observers see all or nothing.
2. **Isolation** — one consistent snapshot of every `TVar` read.
3. **Composition** — combining correct transactions gives a correct transaction.

`transfer = withdraw + deposit` is one line. The lock-based version is a research paper.

---

# Exercises

1. **Reproduce the race.** Run `act1_theRace` ten times. Plot the lost-increment distribution. Why is it never zero, even on one core?

2. **Atomic swap.** `swap :: TVar a -> TVar a -> STM ()`, exchange the contents. Why `STM ()` and not `IO ()`?

3. **Bounded buffer.** Fixed-capacity FIFO of `Int`s using two `TVar`s (list and length). Expose:
   ```haskell
   newBuffer :: Int -> STM (Buffer Int)
   push      :: Buffer a -> a -> STM ()    -- blocks if full
   pop       :: Buffer a -> STM a          -- blocks if empty
   tryPop    :: Buffer a -> STM (Maybe a)
   ```
   `check` for `push`/`pop`, `orElse` for `tryPop`.

4. **Three-way transfer.** `transfer3 :: Account -> Account -> Account -> Money -> STM ()` moves `amount` from `a` to `b` and the same amount from `b` to `c`, in one transaction. Verify with `totalFunds`.

5. **Dining philosophers, no deadlock.** Five philosophers, five chopsticks (each a `TVar Bool`). A philosopher eats by `atomically`-grabbing both adjacent chopsticks. Why does this never deadlock, regardless of `readTVar` order?

6. **Audit log.** Extend `transfer` to append `(from, to, amount)` to a `TVar [LogEntry]`. Why is this still one atomic step? Why would a separate disk logfile not be?

7. **Compare with `MVar`.** Reimplement `Bank` using `MVar Money` per account, plus lock ordering. Run the test suite. How many lines did the implementation grow? Did any test pass that doesn't pass under STM?
