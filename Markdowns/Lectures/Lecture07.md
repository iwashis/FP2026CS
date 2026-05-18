# Monadic Parsing

This lecture follows the classic paper:

> G. Hutton and E. Meijer, *Monadic Parsing in Haskell*, JFP 8(4), 1998.

Everything in here is a direct application of the monad-transformer machinery from the previous lecture — but applied to one very specific instance which turns out to be a complete, expressive parser library.

## A Real-Life Use of `StateT s m` — Parsers

Last time we introduced `StateT s m a ≅ s -> m (a, s)`. We will now pick a very particular instance:

```haskell
s = String     -- the input text being consumed
m = []         -- non-determinism: a parser may succeed in many ways
```

Plug those in:

```haskell
StateT String [] a   ≅   String -> [(a, String)]
```

That type is the central object of Hutton & Meijer. They call it

```haskell
newtype Parser a = Parser (String -> [(a, String)])
```

A `Parser a` takes a string and returns a list of all the ways it can produce a value of type `a` together with the **leftover input** still to be consumed. The empty list means the parser fails on this input.

### Why This Composition is the Right One

Two effects occur in parsing, and they correspond exactly to the two layers of `StateT String []`:

1. **State** (`StateT String`) — the input is consumed left-to-right. Each step reads a prefix and passes the remainder to the next step.
2. **Non-determinism** (`[]`) — a grammar may admit several parses (ambiguity), or several alternatives may be tried (`p` *or* `q`). The list collects them all.

Notice the order matters: the list is *inside* the state, so that *each* alternative carries its own leftover string. Stacking `[]` outside `StateT String` would put the non-determinism on the wrong side.

### Reading `runParser`

For every parser `p :: Parser a` and input `inp :: String`:

```
runParser p inp :: [(a, String)]
```

- `[]`                            — failure, no parse,
- `[(v, "")]`                     — unique complete parse with value `v`,
- `[(v, rest)]`                   — unique parse with leftover `rest`,
- `[(v1, r1), (v2, r2), ...]`     — the grammar is **ambiguous** at this point.

## The Parser Type — Two Equivalent Definitions

In our code we will use the type synonym version and inherit all instances for free:

```haskell
type Parser a = StateT String [] a

runParser :: Parser a -> String -> [(a, String)]
runParser = runStateT
```

The Hutton–Meijer paper predates monad transformers in their modern form, so it defines everything from scratch with a bespoke `newtype`. We get `Functor`, `Applicative`, `Monad`, and `Alternative` for free from `StateT` and `[]`.

The plan for the rest of the lecture:

1. Three primitive parsers: `result`, `zero`, `item`.
2. Sequencing — `(>>=)` comes for free.
3. A `MonadPlus`-flavoured layer: choice (`+++`, `<|>`) and failure.
4. Derived combinators: `sat`, `char`, `string`, `many`, `many1`, `sepby`, `chainl1`.
5. A complete arithmetic-expression parser as a worked example.

## The Three Primitives

### `result` — succeed without consuming input

```haskell
result :: a -> Parser a
result = pure
```

This is the `return` of the parser monad. Concretely it equals `StateT (\s -> [(v, s)])`.

### `zero` — fail

```haskell
zero :: Parser a
zero = StateT (const [])
```

The empty list means: this parser produces no result on any input.

### `item` — consume one character (any character)

```haskell
item :: Parser Char
item = do
  s <- get
  case s of
    c:cs -> do
      put cs
      pure c
    []   -> zero
```

A small session:

```
> runParser item "abc"        -- [('a',"bc")]
> runParser item ""           -- []
> runParser (result 42) "xy"  -- [(42,"xy")]
```

## Sequencing — `(>>=)` for Free

The whole point of monadic parsing is that we can *bind* one parser to the next: the leftover of `p` becomes the input of `f x`. We inherit `>>=` from `StateT String []`:

```haskell
twoChars :: Parser (Char, Char)
twoChars = do
  x <- item
  y <- item
  pure (x, y)
```

```
> runParser twoChars "abc"   -- [(('a','b'),"c")]
> runParser twoChars "a"     -- []
```

The second `item` automatically gets the input left over by the first — that is the `StateT String` part of the inheritance.

## Choice and Failure

Two parsers in parallel — try both, return all parses of either:

```haskell
infixr 5 +++
(+++) :: Parser a -> Parser a -> Parser a
p1 +++ p2 = StateT $ \s -> runStateT p1 s ++ runStateT p2 s
```

Together with `zero`, this gives the structure of a *monad with zero and plus* (today: `Alternative` / `MonadPlus`):

```
zero +++ p          ==  p
p +++ zero          ==  p
(p +++ q) +++ r     ==  p +++ (q +++ r)
zero >>= f          ==  zero
(p +++ q) >>= f     ==  (p >>= f) +++ (q >>= f)
```

### Deterministic choice

Hutton and Meijer observe that for unambiguous grammars one only ever needs the *first* successful parse. Define:

```haskell
infixr 5 <|>
(<|>) :: Parser a -> Parser a -> Parser a
p1 <|> p2 = StateT $ \s ->
  case runStateT p1 s of
    []     -> runStateT p2 s
    parses -> parses
```

Most real grammars use `<|>` because it is dramatically faster — no exponential blow-up of alternatives — and matches what hand-written recursive-descent parsers do.

## Building Blocks: `sat`, `char`, `digit`, `letter`, `space`, `string`

`item` reads any character. We rarely want that — usually we want a character satisfying some predicate. From `sat` everything else flows:

```haskell
sat :: (Char -> Bool) -> Parser Char
sat p = do
  c <- item
  if p c then result c else zero

char :: Char -> Parser Char
char c = sat (== c)

digit :: Parser Char
digit = sat isDigit

letter :: Parser Char
letter = sat isAlpha

spaceP :: Parser Char        -- "P" suffix avoids clashing with Data.Char.space
spaceP = sat isSpace
```

Matching a fixed string is a one-liner by recursion on the pattern:

```haskell
string :: String -> Parser String
string []     = result []
string (c:cs) = do
  _  <- char c
  _  <- string cs
  return (c:cs)
```

```
> runParser (string "let") "let x = 1"   -- [("let"," x = 1")]
> runParser (string "let") "lemon"       -- []
```

This is the *combinator* style: parsers are values you build out of smaller parsers.

## Repetition: `many` and `many1`

```haskell
many :: Parser a -> Parser [a]
many p = many1 p +++ return []

many1 :: Parser a -> Parser [a]
many1 p = do
  x  <- p
  xs <- many p
  return (x:xs)
```

`many1` insists on at least one `p`; `many` accepts zero.

A first useful parser — a non-negative integer:

```haskell
nat :: Parser Int
nat = do
  ds <- many1 digit
  return (read ds)
```

```
> runParser nat "123abc"
[(123,"abc"),(12,"3abc"),(1,"23abc")]
```

Two things to notice:

1. `many1 digit` produces *every* possible split — that is the list monad doing its job.
2. If you want only the longest match, use the deterministic `<|>` version of `many` (just replace `+++` with `<|>` in the definition above).

### Exercise

Define `int :: Parser Int` that also accepts an optional leading `'-'`. Hint:

```haskell
int :: Parser Int
int = neg <|> nat
  where
    neg = do
      _ <- char '-'
      n <- nat
      return (-n)
```

## Whitespace, Tokens, and `sepby`

Most languages allow whitespace between tokens. The standard idiom:

```haskell
spaces :: Parser ()
spaces = do { _ <- many spaceP; return () }

token :: Parser a -> Parser a
token p = do { v <- p; spaces; return v }

symbol :: String -> Parser String
symbol cs = token (string cs)
```

A *token parser* eats trailing whitespace; a top-level parser starts by eating leading whitespace once.

A list of items separated by a separator:

```haskell
sepby1 :: Parser a -> Parser sep -> Parser [a]
p `sepby1` sep = do
  x  <- p
  xs <- many (do { _ <- sep; p })
  return (x:xs)

sepby :: Parser a -> Parser sep -> Parser [a]
p `sepby` sep = (p `sepby1` sep) +++ return []
```

Now we can parse `"[1, 2, 3]"`:

```haskell
intList :: Parser [Int]
intList = do
  _  <- symbol "["
  xs <- token nat `sepby` symbol ","
  _  <- symbol "]"
  return xs
```

## Left-Associative Chains: `chainl1`

Arithmetic expressions need left associativity: `1 - 2 - 3 = (1 - 2) - 3`, not `1 - (2 - 3)`. The standard combinator is:

```haskell
chainl1 :: Parser a -> Parser (a -> a -> a) -> Parser a
p `chainl1` op = do
  x <- p
  rest x
  where
    rest x = (do f <- op
                 y <- p
                 rest (f x y))
             +++ return x
```

Read it like this:

- parse one `p`,
- then *repeatedly* parse `op` followed by another `p`, folding everything to the left,
- when no further `op` parses, return what we have.

### Why `chainl1` and not plain recursion

The "obvious" recursive grammar

```
expr ::= expr "+" term | term
```

is **left-recursive** — a recursive-descent parser written from it loops forever. `chainl1` is the textbook fix: parse one term, then a *flat* sequence of `op term` pairs, folding as you go.

### Exercise

Define `chainr1` for right-associative operators (think `2 ^ 3 ^ 2 = 2 ^ (3 ^ 2)`).

## Worked Example: A Calculator

Grammar:

```
expr   ::= term   ('+' term   | '-' term)*
term   ::= factor ('*' factor | '/' factor)*
factor ::= nat | '(' expr ')'
```

Translation, almost line for line:

```haskell
expr, term, factor :: Parser Int

expr   = term   `chainl1` addop
term   = factor `chainl1` mulop
factor = token nat
     +++ do { _ <- symbol "("; n <- expr; _ <- symbol ")"; return n }

addop  = (symbol "+" >> return (+))
     +++ (symbol "-" >> return (-))

mulop  = (symbol "*" >> return (*))
     +++ (symbol "/" >> return div)

calc :: String -> Int
calc s = case runParser (do { spaces; n <- expr; return n }) s of
  ((n, "") : _) -> n
  _             -> error "parse error"
```

That is a complete, working, left-associative, precedence-respecting expression parser in about ten lines.

```
> calc "1 + 2 * 3"             -- 7
> calc "(1 + 2) * 3"           -- 9
> calc "100 - 10 - 1"          -- 89   (left-associative!)
> calc "2 + 3 * (4 - 1) / 3"   -- 5
```

## Why This Is "Just" `StateT String []`

Every combinator above is forced by the choice of monad:

| H&M name      | What it is in `StateT String []`                          |
|---------------|-----------------------------------------------------------|
| `result`      | `return` of `StateT s []`                                 |
| `zero`        | `lift []`, i.e. `StateT (\_ -> [])`                       |
| `+++`         | `mplus` from `MonadPlus`                                  |
| `>>=`         | `>>=` of `StateT s m`                                     |
| `item`        | `StateT (\s -> case s of (c:cs) -> [(c,cs)]; _ -> [])`    |
| `sat p`       | `do { c <- item; guard (p c); return c }`                 |

So if you build the same library on top of `StateT String []` you get *exactly* the same parsers, just with `lift`, `get`, `put`, and `mplus` written instead of bespoke names.

### Lift to `StateT String IO`?

Replace `[]` with `IO` and you get a parser that can do I/O during parsing — useful for `#include` directives, dynamic loading, etc. Same combinators, just a different inner monad.

## What Modern Libraries Change

The Hutton–Meijer parser is wonderful for teaching. Industrial parser libraries (`parsec`, `megaparsec`, `attoparsec`) refine it in three ways:

1. **Better error reports.** They track an error position and a "what was expected" set, so you do not just get `[]` but a useful message.
2. **Predictive parsing.** They commit after consuming any input (the `try` combinator marks the only places you may backtrack). This rules out exponential blow-ups and gives `O(n)` parsing for `LL(1)` grammars.
3. **Streaming input.** The state is not a `String` but an efficient `Text`/`ByteString` cursor.

But the *core* — a state monad of input strings layered with a non-determinism / failure monad — is still exactly what we built today.

## Exercises

1. Write `between :: Parser open -> Parser close -> Parser a -> Parser a` so that `between (symbol "(") (symbol ")") expr` parses a parenthesised expression.

2. Define `bool :: Parser Bool` that parses `"true"` or `"false"`.

3. Extend the calculator with a unary minus, e.g. `-(1+2) * 3 = -9`. Where in the grammar does it belong — in `factor`, `term`, or `expr`?

4. Add support for floating-point literals to the calculator (parse with `Double` instead of `Int`).

5. Write a parser for a tiny JSON subset:

   ```
   value  ::= number | string | bool | null | array | object
   array  ::= '[' (value (',' value)*)? ']'
   object ::= '{' (pair (',' pair)*)? '}'
   pair   ::= string ':' value
   ```

   You will need a sum data type

   ```haskell
   data JSON
     = JNum  Double
     | JStr  String
     | JBool Bool
     | JNull
     | JArr  [JSON]
     | JObj  [(String, JSON)]
   ```

   and one parser per constructor.

6. Re-implement the whole library on top of `StateT String []` from `Control.Monad.State`. Check that nothing changes from the user's point of view.
