# Calculator

An algebraic calculator built with a hand-written monadic parser in the
Hutton/Meijer style, as introduced in `Lecture07`.

```
expr   ::= term   (('+' | '-') term)*
term   ::= factor (('*' | '/') factor)*
factor ::= '-' factor | nat | '(' expr ')'
```

## Usage

```
stack run -- "1 + 2 * (3 - 4)"
```

## Test suite

The QuickCheck scaffold lives in `test/Spec.hs`. Property bodies and the
`Arbitrary Expr` instance are left as `undefined` — they are filled in
during the QuickCheck lecture.
