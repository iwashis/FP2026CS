module Main (main) where

import qualified Lecture01
import qualified Lecture02
import qualified Tutorials01

main :: IO ()
main = do
  Lecture01.main
  putStrLn ""
  Lecture02.main
  putStrLn ""
  Tutorials01.main
