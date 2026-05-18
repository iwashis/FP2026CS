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
import Test.QuickCheck


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Generator
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

instance Arbitrary Expr where
  arbitrary = undefined
  shrink    = undefined


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Parser / pretty-printer round trips
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- For every expression e:  parseExpr (pretty e) == Just e
prop_pretty_parse_roundtrip :: Expr -> Property
prop_pretty_parse_roundtrip = undefined

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
--  Test runner
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

main :: IO ()
main = do
  quickCheck prop_pretty_parse_roundtrip
  quickCheck prop_parse_pretty_idempotent
  quickCheck prop_add_commutative
  quickCheck prop_add_associative
  quickCheck prop_mul_commutative
  quickCheck prop_add_zero_identity
  quickCheck prop_mul_one_identity
  quickCheck prop_neg_involutive
  quickCheck prop_sub_is_add_neg
  quickCheck prop_calc_matches_pipeline
