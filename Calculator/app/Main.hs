module Main (main) where

import Calculator (calc)
import System.Environment (getArgs)
import System.IO (hIsEOF, stdin)

main :: IO ()
main = do
  args <- getArgs
  case args of
    [] -> repl
    xs -> printResult (calc (unwords xs))

repl :: IO ()
repl = do
  putStrLn "calc> (Ctrl-D to quit)"
  loop
  where
    loop = do
      eof <- hIsEOF stdin
      if eof
        then pure ()
        else do
          line <- getLine
          printResult (calc line)
          loop

printResult :: Maybe Int -> IO ()
printResult (Just n)  = print n
printResult Nothing   = putStrLn "parse error or division by zero"
