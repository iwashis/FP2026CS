-- | Tests that double as executable specifications of the STM invariants the
-- lecture claims. They are deliberately concurrent: each one would be easy to
-- break with a naive lock-based or non-atomic implementation.
module Main (main) where

import Bank
import Control.Concurrent.Async (mapConcurrently_)
import Control.Concurrent.STM
import Control.Monad (forM, replicateM_, unless, void, when)
import System.Exit (exitFailure)
import System.Random (randomRIO)
import Text.Printf (printf)

main :: IO ()
main = do
  results <-
    sequence
      [ test "single transfer moves exactly the amount" testSingleTransfer
      , test "concurrent transfers conserve total funds" testConservation
      , test "balances never go negative under load"     testNoNegative
      , test "tryTransfer reports failure without blocking" testTryTransfer
      , test "transferFromAny picks an account that can pay" testTransferFromAny
      ]
  unless (and results) exitFailure
  putStrLn "All Banking STM properties hold."

-- | Tiny test runner: print a label, run the check, report pass/fail.
test :: String -> IO Bool -> IO Bool
test label action = do
  ok <- action
  printf "[%s] %s\n" (if ok then "PASS" else "FAIL") label
  pure ok

testSingleTransfer :: IO Bool
testSingleTransfer = do
  bank <- newBank 2 100
  let [a, b] = bankAccounts bank
  atomically (transfer a b 40)
  ba <- atomically (balance a)
  bb <- atomically (balance b)
  pure (ba == 60 && bb == 140)

-- | The headline invariant: no matter how many transfers run in parallel, the
-- sum of all balances is unchanged.
testConservation :: IO Bool
testConservation = do
  let numAccounts = 30
      startEach   = 500
  bank <- newBank numAccounts startEach
  before <- atomically (totalFunds bank)
  let accs = bankAccounts bank
  mapConcurrently_ (const (randomWork accs 400)) [1 .. (100 :: Int)]
  after <- atomically (totalFunds bank)
  pure (before == after)

-- | Even with the system fully loaded, 'tryTransfer' must never let a balance
-- drop below zero.
testNoNegative :: IO Bool
testNoNegative = do
  let numAccounts = 20
  bank <- newBank numAccounts 100
  let accs = bankAccounts bank
  mapConcurrently_ (const (randomWork accs 500)) [1 .. (80 :: Int)]
  bals <- forM accs (atomically . balance)
  pure (minimum bals >= 0)

testTryTransfer :: IO Bool
testTryTransfer = do
  bank <- newBank 2 0
  let [a, b] = bankAccounts bank
  atomically (deposit a 30)
  failed  <- atomically (tryTransfer a b 100)  -- not enough -> False
  ok      <- atomically (tryTransfer a b 20)   -- enough     -> True
  pure (failed == False && ok == True)

testTransferFromAny :: IO Bool
testTransferFromAny = do
  bank <- newBank 3 0
  let [a, b, c] = bankAccounts bank
  atomically (deposit b 100)            -- only B can pay
  atomically (transferFromAny [a, b] c 70)
  bb <- atomically (balance b)
  bc <- atomically (balance c)
  pure (bb == 30 && bc == 70)

-- | Fire random non-blocking transfers between random accounts.
randomWork :: [Account] -> Int -> IO ()
randomWork accs n = replicateM_ n $ do
  i      <- randomRIO (0, length accs - 1)
  j      <- randomRIO (0, length accs - 1)
  amount <- randomRIO (1, 25)
  when (i /= j) $
    void (atomically (tryTransfer (accs !! i) (accs !! j) amount))
