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
import Numeric.Natural (Natural)
import System.Environment (getArgs)
import Test.QuickCheck


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Arbitrary Natural
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- This QuickCheck version ships no `Arbitrary Natural`, so we supply one
-- (the `-Wno-orphans` pragma at the top permits the orphan instance).
-- It is exactly QuickCheck's own definition for the other unsigned
-- integral types, e.g. `Word`: `arbitrarySizedNatural` generates a
-- non-negative value scaled to the test size, and `shrinkIntegral`
-- shrinks towards 0 without ever underflowing below zero.

instance Arbitrary Natural where
  arbitrary = arbitrarySizedNatural
  shrink    = shrinkIntegral


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Generator
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

instance Arbitrary Expr where
   -- `Lit` now holds a `Natural`, so its `arbitrary` is non-negative by
   -- construction — no `abs` needed. Negative values are reachable only
   -- through `Neg`, exactly as the parser produces them.
   arbitrary = sized gen
         where
           gen 0 = Lit <$> arbitrary
           gen n = frequency
             [ (1,  Lit <$> arbitrary)
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
prop_pretty_parse_roundtrip e = parseExpr (pretty e) === Just e

-- `pretty` is a canonical form: pretty-printing, parsing, then
-- pretty-printing again yields the very same string.
--   pretty . fromJust . parseExpr . pretty  ==  pretty
prop_parse_pretty_idempotent :: Expr -> Property
prop_parse_pretty_idempotent e =
  fmap pretty (parseExpr (pretty e)) === Just (pretty e)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  Evaluator laws
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Two expressions are "equal" when they evaluate to the same result.
-- Comparing the whole `Maybe Int` (rather than guarding with `==>`) is
-- the point: a division-by-zero on one side must also appear on the
-- other, so `Nothing === Nothing` is a genuine pass. `classify` reports
-- how often the law is exercised on a *defined* value versus a vacuous
-- `Nothing === Nothing`. These identities survive `Int` wraparound
-- because two's-complement arithmetic is a commutative ring.
sameEval :: Expr -> Expr -> Property
sameEval lhs rhs =
  classify (eval lhs == Nothing) "undefined (division by zero)" $
    eval lhs === eval rhs

-- eval (Add a b) == eval (Add b a)
prop_add_commutative :: Expr -> Expr -> Property
prop_add_commutative a b = sameEval (Add a b) (Add b a)

-- eval (Add (Add a b) c) == eval (Add a (Add b c))
prop_add_associative :: Expr -> Expr -> Expr -> Property
prop_add_associative a b c = sameEval (Add (Add a b) c) (Add a (Add b c))

-- eval (Mul a b) == eval (Mul b a)
prop_mul_commutative :: Expr -> Expr -> Property
prop_mul_commutative a b = sameEval (Mul a b) (Mul b a)

-- eval (Add e (Lit 0)) == eval e
prop_add_zero_identity :: Expr -> Property
prop_add_zero_identity e = sameEval (Add e (Lit 0)) e

-- eval (Mul e (Lit 1)) == eval e
prop_mul_one_identity :: Expr -> Property
prop_mul_one_identity e = sameEval (Mul e (Lit 1)) e

-- eval (Neg (Neg e)) == eval e
prop_neg_involutive :: Expr -> Property
prop_neg_involutive e = sameEval (Neg (Neg e)) e

-- eval (Sub a b) == eval (Add a (Neg b))
prop_sub_is_add_neg :: Expr -> Expr -> Property
prop_sub_is_add_neg a b = sameEval (Sub a b) (Add a (Neg b))


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  End-to-end: calc agrees with parseExpr + eval
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- Pretty-print, then run the whole one-shot pipeline: it must agree
-- with evaluating the original expression directly. (Ties `calc`,
-- `parseExpr`, `pretty` and `eval` together via the round trip.)
prop_calc_matches_pipeline :: Expr -> Property
prop_calc_matches_pipeline e = calc (pretty e) === eval e


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--  A law with a precondition  (the `==>` combinator)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- `eval (Div a a) == Just 1`, but ONLY when `a` evaluates to a defined,
-- non-zero number. Contrast this with the laws above: there a `Nothing`
-- appeared identically on both sides, so no guard was needed. Here the
-- excluded cases would make the law genuinely false or vacuous:
--
--   * `eval a == Nothing`  -> Div is Nothing, not Just 1
--   * `eval a == Just 0`   -> 0 / 0 is division by zero -> Nothing
--
-- `==>` discards any input failing the precondition; QuickCheck keeps
-- generating until 100 *satisfy* it, and reports how many it threw away.
-- (Beware: too strict a precondition and QuickCheck gives up.)
prop_div_self :: Expr -> Property
prop_div_self a =
  eval a `notElem` [Nothing, Just 0] ==>
    eval (Div a a) === Just 1


-- ~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
  quickCheck prop_div_self
