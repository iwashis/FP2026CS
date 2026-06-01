-- | A runnable, narrated tour of STM and parallelism, built around a tiny bank.
--
-- Run it with:
--
-- > stack run
--
-- The @-threaded -with-rtsopts=-N@ options (see package.yaml) tell the runtime
-- to actually use every CPU core, so the concurrent acts run in /parallel/.
--
-- The program is a sequence of "acts". Each act is a self-contained mini-lesson
-- you can talk through on its own:
--
--   0. Primitives tour          — forkIO, MVar, async, concurrently, race.
--   1. The race condition       — why plain shared mutable state is wrong.
--   2. STM to the rescue        — the same workload, now correct.
--   3. Blocking with 'retry'    — a thread that waits for money to arrive.
--   4. Choice with 'orElse'     — composing alternatives.
--   5. Parallel stress test     — thousands of transfers; money is conserved.
--   6. The MVar deadlock        — locks fix Act 1 but break composition.
module Main (main) where

import Bank
import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.Async
  ( async, wait, concurrently, concurrently_, race
  , mapConcurrently_, replicateConcurrently_
  )
import Control.Concurrent.MVar
  ( MVar, newEmptyMVar, newMVar, takeMVar, putMVar
  , readMVar, modifyMVar_, withMVar
  )
import Control.Concurrent.STM
import Control.Monad (forM_, replicateM_, void)
import Data.IORef
import GHC.Conc (getNumCapabilities)
import System.Random (randomRIO)
import Text.Printf (printf)

main :: IO ()
main = do
  caps <- getNumCapabilities
  putStrLn "============================================================"
  putStrLn "  Banking: a tour of STM and parallelism in Haskell"
  printf  "  (running on %d hardware capabilities / cores)\n" caps
  putStrLn "============================================================"
  act0_threadingPrimer
  act1_theRace
  act2_stmFix
  act3_retryBlocks
  act4_orElseChoice
  act5_parallelStressTest
  act6_mvarDeadlock
  putStrLn "\nDone. Re-read app/Main.hs and src/Bank.hs alongside the output."

-- Small helper to print act headers consistently.
banner :: String -> IO ()
banner title = do
  putStrLn ""
  putStrLn ("---- " ++ title ++ " " ++ replicate (52 - length title) '-')

--------------------------------------------------------------------------------
-- Act 0: Threading primitives in 30 lines
--------------------------------------------------------------------------------

-- | A short tour of the concurrency vocabulary the rest of the program assumes:
--
--   * 'forkIO' starts a thread.
--   * An 'MVar' is a one-slot box, used here first as a signal ("child done"),
--     then as a lock around a shared counter.
--   * 'async' is the typed, exception-safe replacement for 'forkIO': it returns
--     a handle you can 'wait' on. 'concurrently' runs two actions in parallel
--     and gives you both results; 'race' runs two and gives you the first.
--
-- None of this is STM yet — that comes next.
act0_threadingPrimer :: IO ()
act0_threadingPrimer = do
  banner "Act 0: forkIO, MVar, async — the primitives"
  -- (a) forkIO + MVar as a one-shot signal.
  done <- newEmptyMVar
  _    <- forkIO $ do
    threadDelay 100000
    putStrLn "  [child]  hello from a forked thread"
    putMVar done ()                                     -- signal "I'm done"
  takeMVar done                                         -- parent blocks here
  putStrLn "  [parent] child signalled, moving on."

  -- (b) MVar as a lock — 100 threads, 1000 increments each, *with* protection.
  --     Contrast with Act 1, which is the same workload without a lock.
  lockedCtr <- newMVar (0 :: Int)
  mapConcurrently_
    (\_ -> replicateM_ 1000 (modifyMVar_ lockedCtr (\n -> pure (n + 1))))
    [1 .. 100 :: Int]
  n <- readMVar lockedCtr
  printf "  MVar-protected counter: %d  (expected 100000)\n" n

  -- (c) async / wait — two parallel computations, both results collected.
  a <- async (do threadDelay 50000; pure (1 :: Int))
  b <- async (do threadDelay 50000; pure (2 :: Int))
  xa <- wait a
  xb <- wait b
  printf "  async/wait: %d + %d = %d\n" xa xb (xa + xb)

  -- (d) concurrently — same idea as (c), one line.
  (p, q) <- concurrently (slowReturn "fast" 30000)
                         (slowReturn "slow" 80000)
  printf "  concurrently: %s, %s (both completed)\n" p q

  -- (e) race — first to finish wins; the loser is cancelled.
  winner <- race (slowReturn "fast" 30000)
                 (slowReturn "slow" 80000)
  printf "  race: %s wins (loser cancelled)\n" (either id id winner)
  where
    slowReturn s us = do threadDelay us; pure s

--------------------------------------------------------------------------------
-- Act 1: The race condition
--------------------------------------------------------------------------------

-- | Many threads each add 1 to a shared counter, lots of times. The /correct/
-- answer is obvious. With a plain 'IORef' and a non-atomic read-modify-write,
-- updates are lost: two threads read the same value, both add one, and one
-- increment vanishes. This is the bug STM exists to prevent.
act1_theRace :: IO ()
act1_theRace = do
  banner "Act 1: a data race with a plain IORef"
  let threads     = 100
      perThread   = 1000
      expected    = threads * perThread
  ref <- newIORef (0 :: Int)
  mapConcurrently_
    (\_ -> replicateM_ perThread (modifyIORef ref (+ 1)))  -- NOT atomic!
    [1 .. threads]
  got <- readIORef ref
  printf "expected %d increments, got %d  (lost %d)\n"
         expected got (expected - got)
  putStrLn "modifyIORef is read-then-write; concurrent threads clobber each"
  putStrLn "other. The number is different (and wrong) almost every run."

--------------------------------------------------------------------------------
-- Act 2: STM fixes it
--------------------------------------------------------------------------------

-- | The exact same workload, but the counter lives in a 'TVar' and each
-- increment runs inside 'atomically'. STM detects the conflicting access,
-- re-runs the losing transaction, and the total is always exactly right.
act2_stmFix :: IO ()
act2_stmFix = do
  banner "Act 2: the same workload, correct with STM"
  let threads   = 100
      perThread = 1000
      expected  = threads * perThread
  tv <- newTVarIO (0 :: Int)
  mapConcurrently_
    (\_ -> replicateM_ perThread (atomically (modifyTVar' tv (+ 1))))
    [1 .. threads]
  got <- readTVarIO tv
  printf "expected %d increments, got %d  (lost %d)\n"
         expected got (expected - got)
  putStrLn "Always exact: the read-modify-write is one atomic transaction."

--------------------------------------------------------------------------------
-- Act 3: retry / blocking
--------------------------------------------------------------------------------

-- | A customer tries to withdraw 100 from an empty account. 'withdraw' calls
-- 'check', which 'retry's: the thread blocks instead of failing or busy-waiting.
-- A moment later we deposit the money on the main thread; STM wakes the blocked
-- transaction and it completes by itself. Watch the order of the messages.
act3_retryBlocks :: IO ()
act3_retryBlocks = do
  banner "Act 3: retry — a withdrawal that waits for funds"
  bank <- newBank 1 0
  let [acc] = bankAccounts bank
  -- Spawn the waiting withdrawal.
  void $ replicateConcurrently_ 1 $ do
    putStrLn "  [teller] trying to withdraw 100 from an empty account..."
    atomically (withdrawWhenReady acc 100)
    b <- atomically (balance acc)
    printf "  [teller] withdrawal completed; balance now %d\n" b
  threadDelay 300000  -- let the teller block first (for a tidy demo)
  putStrLn "  [boss]   account is empty, teller is parked (not spinning)."
  putStrLn "  [boss]   depositing 250..."
  atomically (deposit acc 250)
  threadDelay 300000  -- give the woken transaction time to print
  b <- atomically (balance acc)
  printf "  final balance: %d (250 deposited - 100 withdrawn)\n" b

--------------------------------------------------------------------------------
-- Act 4: orElse / choice
--------------------------------------------------------------------------------

-- | 'orElse' composes two transactions as alternatives. We use it twice:
--
--   * 'tryTransfer' turns the blocking 'transfer' into a non-blocking
--     success/failure (no funds => 'False', not a parked thread).
--   * 'transferFromAny' pays a bill from whichever account can currently
--     afford it, trying each in turn.
act4_orElseChoice :: IO ()
act4_orElseChoice = do
  banner "Act 4: orElse — non-blocking attempts and first-that-can-pay"
  bank <- newBank 3 0
  let [a, b, c] = bankAccounts bank
  atomically (deposit a 30)
  atomically (deposit b 200)
  -- tryTransfer: a only has 30, so a -> c of 100 must fail without blocking.
  ok1 <- atomically (tryTransfer a c 100)
  printf "  tryTransfer A->C 100 (A has 30): %s\n" (show ok1)
  ok2 <- atomically (tryTransfer b c 100)
  printf "  tryTransfer B->C 100 (B has 200): %s\n" (show ok2)
  -- transferFromAny: pay C 80 from the first of [A,B] that can afford it.
  atomically (transferFromAny [a, b] c 80)
  putStrLn "  transferFromAny [A,B] -> C 80: took it from the first able account"
  forM_ (bankAccounts bank) $ \acc -> do
    bal <- atomically (balance acc)
    printf "    account %d balance: %d\n" (accountId acc) bal

--------------------------------------------------------------------------------
-- Act 5: parallel stress test
--------------------------------------------------------------------------------

-- | The real demonstration. Open a bank, then unleash many worker threads that
-- concurrently fire off thousands of random transfers between random accounts.
-- Transfers never overdraw (STM guarantees it) and, crucially, the /total/
-- amount of money in the bank is identical before and after — every cent that
-- leaves one account lands in another, atomically.
act5_parallelStressTest :: IO ()
act5_parallelStressTest = do
  banner "Act 5: parallel stress test — money is conserved"
  let numAccounts = 50
      startEach   = 1000
      workers     = 200
      opsPerWorker = 500
  bank <- newBank numAccounts startEach
  before <- atomically (totalFunds bank)
  printf "  %d accounts x %d = %d total before\n"
         numAccounts startEach before
  printf "  launching %d workers x %d transfers = %d concurrent transfers...\n"
         workers opsPerWorker (workers * opsPerWorker)

  let accs = bankAccounts bank
  mapConcurrently_ (const (worker accs opsPerWorker)) [1 .. workers]

  after <- atomically (totalFunds bank)
  printf "  total after: %d\n" after
  if before == after
    then putStrLn "  CONSERVED: not a single cent created or destroyed. STM works."
    else printf  "  BUG: money changed by %d (should be impossible)\n" (after - before)
  -- Also show no account went negative.
  bals <- mapM (atomically . balance) accs
  printf "  min balance across accounts: %d (never negative)\n" (minimum bals)

-- | One worker performs @n@ random, non-blocking transfers. We use
-- 'tryTransfer' so a worker never parks waiting on an underfunded account —
-- it just moves on, keeping all cores busy.
worker :: [Account] -> Int -> IO ()
worker accs n = replicateM_ n $ do
  i      <- randomRIO (0, length accs - 1)
  j      <- randomRIO (0, length accs - 1)
  amount <- randomRIO (1, 50)
  if i == j
    then pure ()
    else void (atomically (tryTransfer (accs !! i) (accs !! j) amount))

--------------------------------------------------------------------------------
-- Act 6: The MVar deadlock — composition is hard without STM
--------------------------------------------------------------------------------

-- | An "account" the lock-based way: a balance in an 'IORef', guarded by an
-- 'MVar' used as a mutex. Touching the balance requires holding the lock.
data MAccount = MAccount
  { mLock    :: !(MVar ())
  , mBalance :: !(IORef Money)
  }

newMAccount :: Money -> IO MAccount
newMAccount initial = MAccount <$> newMVar () <*> newIORef initial

-- | The natural lock-based transfer: grab @from@'s lock, then @to@'s lock,
-- then update both balances. The 'threadDelay' is *not* essential — it just
-- makes the deadlock manifest immediately every run instead of intermittently.
mTransfer :: MAccount -> MAccount -> Money -> IO ()
mTransfer from to amount =
  withMVar (mLock from) $ \_ -> do
    threadDelay 10000                -- 10ms pause to let the other thread grab its first lock
    withMVar (mLock to) $ \_ -> do
      modifyIORef' (mBalance from) (subtract amount)
      modifyIORef' (mBalance to)   (+ amount)

-- | Two threads, two accounts, opposite transfer directions. Thread 1 grabs
-- lock A then waits for B; thread 2 grabs B then waits for A. Classic deadlock.
-- We use 'race' against a 1-second timeout to detect it without hanging the demo.
act6_mvarDeadlock :: IO ()
act6_mvarDeadlock = do
  banner "Act 6: transfer with two MVar locks deadlocks"
  a <- newMAccount 1000
  b <- newMAccount 1000
  outcome <- race
    (concurrently_ (mTransfer a b 100)   -- thread 1: A then B
                   (mTransfer b a 100))  -- thread 2: B then A
    (do threadDelay 1000000; pure ())    -- 1-second referee
  case outcome of
    Left _  -> putStrLn "  both finished (got lucky on scheduling — try again)"
    Right _ -> do
      putStrLn "  DEADLOCK: both threads blocked for 1s without progress."
      putStrLn "  Thread 1 holds A's lock and waits for B."
      putStrLn "  Thread 2 holds B's lock and waits for A. Neither will move."
  ba <- readIORef (mBalance a)
  bb <- readIORef (mBalance b)
  printf "  balances frozen at: A=%d, B=%d (no debit, no credit)\n" ba bb
  putStrLn "  Fix: order locks by account id in *every* function that takes two."
  putStrLn "  Compare Act 4 — the STM 'transfer' composes with no ordering at all."
