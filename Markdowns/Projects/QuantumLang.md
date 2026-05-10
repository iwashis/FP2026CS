# Quantum Computing Language

## Motivation

Quantum-computing toolkits — Qiskit, Cirq, Q#, Quipper — let researchers describe quantum circuits and either run them on simulators or dispatch them to real quantum hardware. Underneath, a simulator for a few qubits is a few-hundred-line linear-algebra exercise: gates are unitary matrices, states are complex vectors of length `2^n`, and measurement is sampling weighted by squared amplitudes. The interesting things — superposition, entanglement, the Born rule — fall out of that linear algebra without anything mystical. This project is exactly that simulator, with a small DSL on top so that a "program" looks like a circuit. It is also an unusually clean place to meet phenomena like Bell-state correlations and quantum teleportation in code form.

## Project Overview
This project implements a small domain-specific language for describing quantum circuits. Programs initialise a register of qubits, apply a sequence of gates, measure, and (optionally) branch on measurement results.

## Key Goals
1. **Parser Implementation**: Convert quantum programs into a structured AST.
2. **Quantum Simulator**: Execute the program by maintaining a state vector and applying gates as unitary matrices.
3. **Test Suite**: Cover the parser, individual gates, and a handful of small circuits with known outcomes.
4. **Circuit Visualisation (stretch)**: Render the parsed program as a circuit diagram (ASCII grid is fine).

## Suggested Core Data Types

A starting point — adapt to your design. In particular, you do **not** need a separate constructor per gate; a small `Gate` type plus an `Apply` statement keeps the AST compact and makes adding gates cheap.

```haskell
data Program = Program [Statement]

data Statement
  = Init    Int                       -- create a register of n qubits
  | Apply   Gate [Int]                -- apply a gate to the listed qubit indices
  | Measure Int String                -- measure qubit i, store the bit in a variable
  | If      String [Statement]        -- run the body if the named bit is 1
  | Repeat  Int [Statement]
  | Print   String
  | ...

data Gate
  = H | X | Y | Z | CNOT
  | Phase Double                      -- extend with whatever your project needs
  | ...
```

## Example Program: Bell State
```
// Bell state creation and measurement
init 2

apply H    [0]
apply CNOT [0, 1]

measure 0 -> m0
measure 1 -> m1

print m0
print m1

// m0 and m1 should always agree (both 0 or both 1)
```

## Implementation Components

### 1. Parser
- Parse `init`, `apply`, `measure`, control flow, and `print`.
- Report syntax errors with useful location information.
- Support comments.

### 2. Quantum Simulator
- Maintain the state of an `n`-qubit register as a complex vector of length `2^n`.
- Provide unitary matrices for the gates you support and apply them to the right qubits via the appropriate tensor structure (you do not need to materialise huge tensor products — apply gates index-wise).
- Implement measurement probabilistically according to the Born rule and collapse the state accordingly.
- Track measurement outcomes in a small environment of named bits so that conditional statements work.

### 3. Test Suite
- **Unit tests**: parser correctness; each gate's matrix is unitary; measurement of a basis state returns the expected bit deterministically.
- **End-to-end tests**: Bell-state correlations; quantum teleportation; a small Deutsch-style circuit — programs whose outcome distribution is known by hand.
- **Property-based tests**: after any sequence of gates, the state vector remains normalised; measurement probabilities sum to one.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
