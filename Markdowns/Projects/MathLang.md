# MathLang: A Language for Linear Algebra and Calculus

## Motivation

Symbolic mathematics systems — Mathematica, Maple, SymPy — and the numeric ecosystems built around tensors — NumPy, MATLAB, Julia, PyTorch — are some of the most-used tools in science and engineering. The expression-tree machinery underneath them is a textbook application of functional programming: pattern-matching on AST nodes is exactly how symbolic differentiation, algebraic simplification, and dimensional analysis are written. This project is a small language for vector and matrix expressions, with optional symbolic differentiation as a stretch goal — small enough to implement in a course, large enough to make the underlying ideas visible. It is also a good vehicle for thinking about *type* errors that are not the usual kind: dimension mismatches, non-conformable products, derivatives with respect to the wrong variable.

## Project Overview
MathLang is a small domain-specific language for expressing linear-algebra and calculus computations. The syntax should stay close to ordinary mathematical notation while being precise enough that an evaluator can run it.

## Key Goals
1. **Parser Implementation**: Convert mathematical notation into a structured AST.
2. **Expression Evaluator**: Evaluate scalar, vector, and matrix expressions; handle dimension errors cleanly.
3. **Test Suite**: Cover the parser, the numeric evaluator, and a handful of small computations.
4. **Symbolic Differentiation (stretch)**: Compute symbolic derivatives of MathLang expressions with respect to a named variable, with at least basic algebraic simplification.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
data Program = Program [Definition] Expr

data Definition
  = FuncDef String [String] Expr       -- f(x, y) = ...
  | VarDef  String Expr                -- x = ...
  | ...

data Expr
  = Var       String
  | ScalarLit Double
  | VecLit    [Expr]
  | MatLit    [[Expr]]
  | BinOp     Op Expr Expr
  | Apply     String [Expr]            -- function call by name
  | Let       String Expr Expr
  | ...
```

If your project tackles symbolic differentiation, you'll want to add an explicit form for it; the natural shape is `Deriv String Expr` (derivative with respect to a *named* variable, not an arbitrary expression).

```haskell
data Op = Add | Sub | Mul | Div | Dot | ...   -- extend as needed; e.g. Transpose can be a unary form
```

## Example Program
```
// Linear-regression loss and its gradient at a point

def loss(X, y, theta) =
  let preds  = X * theta in
  let errors = preds - y in
  (1 / 2) * dot(errors, errors)

let X     = [[1, 2], [1, 3], [1, 4]] in
let y     = [2, 3.5, 4.8] in
let theta = [0, 0] in

loss(X, y, theta)
```

## Implementation Components

### 1. Parser
- Parse definitions, expressions, and literal vectors/matrices.
- Get operator precedence right (multiplication binds tighter than addition, etc.).
- Report syntax errors with useful location information.
- Support comments.

### 2. Expression Evaluator
- Evaluate scalar arithmetic, then vector/matrix operations on top.
- Reject dimension mismatches (e.g. multiplying incompatible matrices) with a clear message.
- Resolve variable and function definitions in the program's environment.

### 3. Test Suite
- **Unit tests**: parser correctness; arithmetic on scalars; vector/matrix shape checks; a handful of named identities (associativity, distributivity on small inputs).
- **End-to-end tests**: a few small programs whose results you can compute by hand.
- **Property-based tests**: random small expressions checked against an oracle (e.g. compare your matrix product with the obvious nested-loop version on random inputs).

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `Project/` folder next to the existing `Homework/` folder.
