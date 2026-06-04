# BlockChainLang: A Language for Smart Contracts

## Motivation

Smart-contract platforms like Ethereum and Solana run deterministic virtual machines over a shared, append-only ledger; the rules of each contract are code, and the chain is what enforces them. The interesting parts of such a system, from a programming-languages point of view, have nothing to do with cryptography or networking — they are about how a transaction either commits its state changes atomically or leaves the world untouched, and how multiple contracts share one ledger without stepping on each other. This project strips the network and crypto away and leaves just that core: a small contract language, a tiny VM, and an append-only chain of transactions that exercise it.

## Project Overview
BlockChainLang is a small domain-specific language for describing simple blockchains and smart contracts. Programs declare contract state, the kinds of transactions that can update it, and the validation rules each transaction must satisfy. The runtime maintains a chain of blocks made of those transactions.

## Key Goals
1. **Parser Implementation**: Convert contract definitions into a structured AST.
2. **Ledger & Virtual Machine**: Maintain a chain of blocks plus the current contract state, and execute transaction bodies against that state. Each block holds a list of transactions and a reference to its parent; the runtime must enforce the chain invariant (every non-genesis block names its parent and that parent exists).
3. **Test Suite**: Cover the parser, individual transactions, and a handful of end-to-end scenarios (transfers, double-spend attempts, …).

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
data Contract = Contract [StateVar] [TransactionDef]

data StateVar = StateVar
  { svName :: String
  , svType :: Type
  , svInit :: Expr
  }

data TransactionDef = TransactionDef
  { txName    :: String
  , txParams  :: [(String, Type)]
  , txBody    :: [Statement]
  }

data Type
  = TInt | TBool | TAddress
  | TMap Type Type
  | ...

data Expr
  = Var    String
  | Lit    Value
  | BinOp  Op Expr Expr
  | Index  Expr Expr        -- map[key]
  | Sender                  -- address that submitted the transaction (see below)
  | ...

data Statement
  = Assign  Expr Expr       -- balances[from] := balances[from] - amount
  | Require Expr            -- abort the transaction unless this holds
  | If      Expr [Statement] [Statement]
  | ...
```

Addresses are simply opaque identifiers. There is no cryptography in the base project — when a test driver submits a transaction, it states which address is the `sender`, and the runtime trusts that label. (The stretch goal is the only place hashes appear.)

## Example Contract
```
contract SimpleCoin {
  state {
    balances: map<address, int> = empty;
    owner:    address          = sender;
  }

  transaction transfer(to: address, amount: int) {
    require balances[sender] >= amount;
    balances[sender] := balances[sender] - amount;
    balances[to]     := balances[to] + amount;
  }
}
```

## Implementation Components

### 1. Parser
- Parse contract declarations, state variables, and transaction definitions.
- Report syntax errors with useful location information.
- Support comments.

### 2. Ledger & Virtual Machine
- Maintain a chain of blocks; each block is a list of transactions plus a reference to the previous block. The genesis block is the only one without a parent; every other block's parent reference must point at an existing block.
- Execute a transaction by evaluating its body against the current state; a failed `require` reverts every change the transaction made (the rest of the block proceeds).
- Provide a way to submit a block of transactions, and to query the current state.
- Reject transactions that violate basic well-formedness rules (unknown transaction name, wrong number of arguments, type mismatch, …) and reject blocks whose parent reference is missing or unknown.

### 3. Test Suite
- **Unit tests**: parser correctness; individual transactions executed in isolation; that a failing `require` rolls the state back.
- **End-to-end tests**: a small `SimpleCoin`-style contract under sequences of transfers, including a double-spend attempt that must be rejected.
- **Property-based tests**: invariants of the ledger — e.g. for `SimpleCoin`, total supply is preserved across any sequence of transfers.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
