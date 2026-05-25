{-# OPTIONS_GHC -Wno-unused-imports -Wno-orphans #-}
module Main (main) where

--
-- ==========================================
--  QuickCheck scaffold for Calculator
-- ==========================================
--
-- The properties below are deliberately left `undefined`. They are
-- filled in during the QuickCheck lecture. The goal is for students
-- to:
--
--   1. write a sensible `Arbitrary Expr` generator,
--   2. realise *which* equational laws survive once Int overflow and
--      division-by-zero are taken into account,
--   3. learn the QuickCheck combinators (`==>`, `forAll`, `classify`,
--      `shrink`, `withMaxSuccess`, ...) by rewriting these stubs.
--

import Calculator (Expr (..), calc, eval, parseExpr, pretty)
import Data.List (sort, nub)
import System.Environment (getArgs)
import Test.QuickCheck


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Generator
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

instance Arbitrary Expr where
   arbitrary = sized gen
         where
           gen 0 = Lit <$> fmap abs arbitrary
           gen n = frequency
             [ (1,  Lit <$> fmap abs arbitrary)
             , (1, Neg <$> gen (n - 1))
             , (2, bin Add), (2, bin Sub)
             , (2, bin Mul), (2, bin Div) ]
             where
               half  = n `div` 2
               bin c = c <$> gen half <*> gen half

   shrink (Lit n)   = [ Lit n' | n' <- shrink n ]
   shrink (Neg e)   = e : [ Neg e' | e' <- shrink e ]
   shrink (Add a b) = [a, b] ++ [ Add a' b | a' <- shrink a ] ++ [ Add a b' | b' <- shrink b ]
   shrink (Sub a b) = [a, b] ++ [ Sub a' b | a' <- shrink a ] ++ [ Sub a b' | b' <- shrink b ]
   shrink (Div a b) = [a, b] ++ [ Div a' b | a' <- shrink a ] ++ [ Div a b' | b' <- shrink b ]
   shrink (Mul a b) = [a, b] ++ [ Mul a' b | a' <- shrink a ] ++ [ Mul a b' | b' <- shrink b ]


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Parser / pretty-printer round trips
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- For every expression e:  parseExpr (pretty e) == Just e
prop_pretty_parse_roundtrip :: Expr -> Property
prop_pretty_parse_roundtrip e =  parseExpr (pretty e) === Just e 

-- For every well-formed input s that parses to e:
--   pretty (fromJust (parseExpr s))  parses back to the same e
prop_parse_pretty_idempotent :: Expr -> Property
prop_parse_pretty_idempotent = undefined


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Evaluator laws
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- eval (Add a b) == eval (Add b a)
prop_add_commutative :: Expr -> Expr -> Property
prop_add_commutative = undefined

-- eval (Add (Add a b) c) == eval (Add a (Add b c))
prop_add_associative :: Expr -> Expr -> Expr -> Property
prop_add_associative = undefined

-- eval (Mul a b) == eval (Mul b a)
prop_mul_commutative :: Expr -> Expr -> Property
prop_mul_commutative = undefined

-- eval (Add e (Lit 0)) == eval e
prop_add_zero_identity :: Expr -> Property
prop_add_zero_identity = undefined

-- eval (Mul e (Lit 1)) == eval e
prop_mul_one_identity :: Expr -> Property
prop_mul_one_identity = undefined

-- eval (Neg (Neg e)) == eval e
prop_neg_involutive :: Expr -> Property
prop_neg_involutive = undefined

-- eval (Sub a b) == eval (Add a (Neg b))
prop_sub_is_add_neg :: Expr -> Expr -> Property
prop_sub_is_add_neg = undefined


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  End-to-end: calc agrees with parseExpr + eval
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

prop_calc_matches_pipeline :: Expr -> Property
prop_calc_matches_pipeline = undefined


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Shrinking demo on [Int]
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Lists already have a perfectly good `Arbitrary` / `shrink` instance
-- in QuickCheck, so they make an ideal stage on which to *watch*
-- shrinking work. All three properties below are deliberately FALSE.
-- When you run them you should see QuickCheck:
--
--   1. find a random counterexample of some non-trivial size,
--   2. then shrink it down to the smallest list (and smallest element
--      values) that still falsifies the property.
--
-- Expected minimal counterexamples (your run may pick the symmetric
-- variant, e.g. [1,0] vs [0,1] — both are length-2 minima):
--
--   prop_reverse_id        -> [0, 1]
--   prop_already_sorted    -> [1, 0]
--   prop_no_duplicates     -> [0, 0]

-- FALSE: claims reversing a list is the identity.
prop_reverse_id :: [Int] -> Property
prop_reverse_id xs = reverse xs === xs

-- FALSE: claims every list is already sorted.
prop_already_sorted :: [Int] -> Property
prop_already_sorted xs = sort xs === xs

-- FALSE: claims lists never contain duplicates.
prop_no_duplicates :: [Int] -> Property
prop_no_duplicates xs = nub xs === xs


-- ~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Test runner
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

main :: IO ()
main = do
  print $ pretty $ Lit (-1)
  print $ parseExpr "(-1)"
  quickCheck prop_pretty_parse_roundtrip
  -- args <- getArgs
  -- let verboseMode = any (`elem` args) ["-v", "--verbose"]
  --     -- `verboseShrinking` prints every shrink attempt (pass *or* fail);
  --     -- plain `quickCheck` only shows the final minimal counterexample.
  --     runDemo p
  --       | verboseMode = quickCheck (verboseShrinking (expectFailure p))
  --       | otherwise   = quickCheck (expectFailure p)
  -- putStrLn $ "-- shrinking demo (intentionally false properties)"
  --         ++ (if verboseMode then " [VERBOSE]" else "")
  --         ++ " --"
  -- -- Pass --verbose (e.g. `stack test --ta -v`) to see every shrink step.
  -- runDemo prop_reverse_id
  -- runDemo prop_already_sorted
  -- runDemo prop_no_duplicates
  -- putStrLn "-- Expr properties (filled in during the QuickCheck lecture) --"
  -- quickCheck prop_pretty_parse_roundtrip
  -- quickCheck prop_parse_pretty_idempotent
  -- quickCheck prop_add_commutative
  -- quickCheck prop_add_associative
  -- quickCheck prop_mul_commutative
  -- quickCheck prop_add_zero_identity
  -- quickCheck prop_mul_one_identity
  -- quickCheck prop_neg_involutive
  -- quickCheck prop_sub_is_add_neg
  -- quickCheck prop_calc_matches_pipeline
