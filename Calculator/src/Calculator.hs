module Calculator
  ( -- * Expression AST
    Expr (..)

    -- * Parser
  , parseExpr

    -- * Evaluator
  , eval

    -- * Pretty printer
  , pretty

    -- * One-shot
  , calc
  ) where

import Control.Monad.State
import Data.Char (isDigit, isSpace)
import Numeric.Natural (Natural)

--
-- ==========================================
--  Calculator — an algebraic expression
--  language built on the Hutton/Meijer
--  monadic parser from Lecture 7.
-- ==========================================
--
-- Grammar:
--   expr   ::= term   (('+' | '-') term)*
--   term   ::= factor (('*' | '/') factor)*
--   factor ::= '-' factor | nat | '(' expr ')'
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 1. The AST
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- A literal is a *natural* number: the grammar's @nat@ rule never
-- produces a sign, and negation is represented explicitly by 'Neg'.
-- Using 'Natural' makes that invariant impossible to violate.
data Expr
  = Lit Natural
  | Neg Expr
  | Add Expr Expr
  | Sub Expr Expr
  | Mul Expr Expr
  | Div Expr Expr
  deriving (Eq, Show)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 2. The Parser type (StateT String [])
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

type Parser a = StateT String [] a

runParser :: Parser a -> String -> [(a, String)]
runParser = runStateT


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 3. Primitives
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

zero :: Parser a
zero = StateT (const [])

item :: Parser Char
item = do
  s <- get
  case s of
    c : cs -> put cs >> pure c
    []     -> zero


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 4. Choice (deterministic — first success wins)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

infixr 5 <|>
(<|>) :: Parser a -> Parser a -> Parser a
p1 <|> p2 = StateT $ \s ->
  case runStateT p1 s of
    []     -> runStateT p2 s
    parses -> parses


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 5. Building blocks
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sat :: (Char -> Bool) -> Parser Char
sat predicate = do
  c <- item
  if predicate c then pure c else zero

char :: Char -> Parser Char
char c = sat (== c)

digit :: Parser Char
digit = sat isDigit

spaceP :: Parser Char
spaceP = sat isSpace

many :: Parser a -> Parser [a]
many p = many1 p <|> pure []

many1 :: Parser a -> Parser [a]
many1 p = do
  x  <- p
  xs <- many p
  pure (x : xs)

string :: String -> Parser String
string []       = pure []
string (c : cs) = do
  _  <- char c
  _  <- string cs
  pure (c : cs)

spaces :: Parser ()
spaces = do
  _ <- many spaceP
  pure ()

token :: Parser a -> Parser a
token p = do
  v <- p
  spaces
  pure v

symbol :: String -> Parser String
symbol cs = token (string cs)

nat :: Parser Natural
nat = do
  ds <- many1 digit
  pure (read ds)

chainl1 :: Parser a -> Parser (a -> a -> a) -> Parser a
chainl1 p op = p >>= rest
  where
    rest x =
      (do
         f <- op
         y <- p
         rest (f x y))
      <|> pure x


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 6. The grammar
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

expr, term, factor :: Parser Expr
expr = term `chainl1` addop
term = factor `chainl1` mulop
factor =
      neg
  <|> lit
  <|> paren
  where
    neg = do
      _ <- symbol "-"
      e <- factor
      pure (Neg e)

    lit = do
      n <- token nat
      pure (Lit n)

    paren = do
      _ <- symbol "("
      e <- expr
      _ <- symbol ")"
      pure e

addop, mulop :: Parser (Expr -> Expr -> Expr)
addop =
      (symbol "+" >> pure Add)
  <|> (symbol "-" >> pure Sub)

mulop =
      (symbol "*" >> pure Mul)
  <|> (symbol "/" >> pure Div)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 7. Top-level parser
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

parseExpr :: String -> Maybe Expr
parseExpr s =
  case runParser (spaces >> expr) s of
    ((e, "") : _) -> Just e
    _             -> Nothing


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 8. Evaluator (Maybe to signal division by zero)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

eval :: Expr -> Maybe Int
eval (Lit n)   = Just (fromIntegral n)
eval (Neg e)   = negate <$> eval e
eval (Add a b) = (+) <$> eval a <*> eval b
eval (Sub a b) = (-) <$> eval a <*> eval b
eval (Mul a b) = (*) <$> eval a <*> eval b
eval (Div a b) = do
  x <- eval a
  y <- eval b
  if y == 0 then Nothing else Just (x `div` y)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 9. Pretty printer (fully parenthesised — easy round-trip target)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pretty :: Expr -> String
pretty (Lit n)   = show n
pretty (Neg e)   = "(-" ++ pretty e ++ ")"
pretty (Add a b) = "(" ++ pretty a ++ " + " ++ pretty b ++ ")"
pretty (Sub a b) = "(" ++ pretty a ++ " - " ++ pretty b ++ ")"
pretty (Mul a b) = "(" ++ pretty a ++ " * " ++ pretty b ++ ")"
pretty (Div a b) = "(" ++ pretty a ++ " / " ++ pretty b ++ ")"


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 10. One-shot: parse and evaluate
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

calc :: String -> Maybe Int
calc s = parseExpr s >>= eval

-- ghci> calc "1 + 2 * 3"             -- Just 7
-- ghci> calc "(1 + 2) * 3"           -- Just 9
-- ghci> calc "100 - 10 - 1"          -- Just 89   (left-associative!)
-- ghci> calc "2 + 3 * (4 - 1) / 3"   -- Just 5
-- ghci> calc "-(1 + 2) * 3"          -- Just (-9)
-- ghci> calc "1 / 0"                 -- Nothing
