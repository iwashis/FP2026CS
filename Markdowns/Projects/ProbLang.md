# Probabilistic Programming Language

## Motivation

Probabilistic programming languages — Stan, PyMC, Pyro, Turing.jl, Anglican — let scientists and engineers express statistical models as ordinary-looking programs and ask the runtime to perform inference for them. They are how a great deal of modern Bayesian statistics is actually written, and they sit at the interface between programming languages and machine learning. The two-part trick that makes them work — separate the *model* (random draws and observations) from the *inference algorithm* — is a beautiful example of how an abstraction earns its keep. This project is a small probabilistic language plus a from-scratch sampler: small enough to fit in a course project, large enough that the same model expressed in your DSL gives the same posterior an off-the-shelf tool would.

## Project Overview
This project implements a small domain-specific language for stating probabilistic models and running approximate inference on them. Users describe random variables and their distributions, condition on observations, and ask for the posterior distribution of a quantity of interest.

## Key Goals
1. **Parser Implementation**: Convert probabilistic programs into a structured AST.
2. **Model & Inference Engine**: Build the probabilistic model and run a sampling-based inference procedure (rejection sampling or MCMC are reasonable starting points).
3. **Test Suite**: Cover the parser, the samplers, and a handful of small models with known analytic answers.
4. **Alternative Inference (stretch)**: Add a second inference method (e.g. importance sampling) and compare it with your baseline on the same models.

## Suggested Core Data Types

A starting point — adapt to your design. The set of distributions is up to you; the shapes below carry parameters generically.

```haskell
data Program = Program [Statement]

data Statement
  = Sample  String Distribution            -- x ~ D
  | Let     String Expr                    -- x = e (deterministic)
  | Observe Distribution Expr              -- observed value drawn from D
  | If      Expr [Statement] [Statement]
  | Return  [String]                       -- variables of interest
  | ...

-- Distributions: name + parameter expressions
data Distribution = Distribution String [Expr]

data Expr
  = Var String
  | Lit Value
  | BinOp Op Expr Expr
  | If'   Expr Expr Expr
  | ...

data Value = RealV Double | IntV Int | BoolV Bool | ...

data Op = Add | Sub | Mul | Div | Eq | Lt | And | Or | ...
```

The set of supported distributions (Bernoulli, Normal, Beta, …) lives in your interpreter, not in the AST.

## Example Program: Medical Diagnosis
```
// Bayesian medical diagnosis

has_disease ~ Bernoulli(0.01);

let tp = 0.95;     // sensitivity
let fp = 0.10;     // 1 - specificity

if has_disease then {
  test ~ Bernoulli(tp);
} else {
  test ~ Bernoulli(fp);
}

observe test = 1;

return [has_disease];
```

The interpreter then runs inference and reports the empirical posterior of `has_disease`.

## Implementation Components

### 1. Parser
- Parse the statements and expressions above.
- Report syntax errors with useful location information.
- Support comments.

### 2. Model & Inference Engine
- Build a representation of the model from the statement list.
- Implement at least one sampling procedure (rejection sampling is the simplest correct choice for small discrete models; an MCMC kernel scales further).
- Handle observations correctly — either by conditioning during sampling or by re-weighting traces.
- Report the posterior of the requested variables as samples and/or summary statistics.

### 3. Test Suite
- **Unit tests**: parser correctness; samplers for individual distributions match their expected mean/variance within tolerance over enough draws.
- **End-to-end tests**: a few small models whose posterior can be computed analytically (e.g. the medical-test example above); compare your sampler's output to the closed-form answer.
- **Property-based tests**: invariants such as `Bernoulli(0)` always returning `0`, sums over a categorical's probabilities, and that the empirical mean of `n` samples from `Normal(mu, sigma)` is within an `O(sigma / sqrt(n))` band around `mu`.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `Project/` folder next to the existing `Homework/` folder.
