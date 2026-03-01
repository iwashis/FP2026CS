module Main (main) where

import qualified Lecture01
import qualified Lecture02

main :: IO ()
main = do
  Lecture01.main
  putStrLn ""
  Lecture02.main
