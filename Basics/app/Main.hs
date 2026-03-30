module Main (main) where

import qualified Lecture01
import qualified Lecture02
import qualified Tutorials01
import qualified Tutorials02
import qualified Tutorials03
import qualified Tutorials04
main :: IO ()
main = do
  Lecture01.main
  putStrLn ""
  Lecture02.main
  putStrLn ""
  Tutorials01.main
  putStrLn ""
  Tutorials02.main
  putStrLn ""
  Tutorials03.main
  putStrLn ""
  Tutorials04.main
