# SqlLiteClone: An In-Memory Relational Database

## Motivation

SQL has been the dominant data-query language for almost half a century, and the engines that run it (SQLite, PostgreSQL, DuckDB) are some of the most-used pieces of software in existence. Underneath the surface syntax sits relational algebra — projection, selection, join — a small set of operators with very clean composition properties. This project is a small SQL frontend over an in-memory implementation of those operators: parse a query, build a relational-algebra tree, run it. It is also a natural place to meet *query optimisation* — the same query expressed in equivalent ways can be orders of magnitude apart in cost, which is why the optimisation step in a real database is one of the most studied parts of any production system.

## Project Overview
SqlLiteClone is a small SQL-like query language and an in-memory engine that runs queries against tables held entirely in memory. The intent is to cover the relational core — schema definition, insertion, selection, projection, and a join — and leave room for an optimisation step on top.

## Key Goals
1. **Parser Implementation**: Convert SQL-like queries into a structured AST.
2. **Query Engine**: Maintain in-memory tables and execute parsed queries against them.
3. **Test Suite**: Cover the parser, individual relational operations, and a handful of end-to-end queries with hand-computed answers.
4. **Query Optimisation (stretch)**: Add a small optimisation pass — selection push-down, projection push-down, or join reordering — and demonstrate it on at least one query whose physical plan changes.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
data Statement
  = CreateTable String [ColumnDef]
  | Insert      String [Value]
  | Query       Query
  | ...

data ColumnDef = ColumnDef { colName :: String, colType :: ColType }

data ColType = TInt | TString | TBool | ...

data Value = IntV Int | StrV String | BoolV Bool | NullV | ...

-- A query expression: pick the shape that makes your engine easy to write
data Query
  = From    String                    -- entire table
  | Project [String] Query
  | Filter  Cond Query
  | Join    Query Query Cond
  | ...

data Cond
  = CmpCol String CmpOp Value
  | And    Cond Cond
  | Or     Cond Cond
  | ...

data CmpOp = Eq | NEq | Lt | Le | Gt | Ge | ...
```

A relational-algebra-shaped AST (as above) tends to be much easier to evaluate and optimise than the surface SQL shape — it is fine to parse SQL into this representation directly.

## Example
```
create table Users (id int, name string);
insert into Users values (1, "Alice");
insert into Users values (2, "Bob");

select name from Users where id = 1;
```

## Implementation Components

### 1. Parser
- Parse `CREATE TABLE`, `INSERT`, and `SELECT` (with `WHERE` and at least one `JOIN`).
- Report syntax errors with useful location information.
- Support comments.

### 2. Query Engine
- Maintain tables as in-memory data (lists of rows, maps from primary key to row, …).
- Implement projection, selection, and an inner join — even the obvious nested-loop join is fine.
- Reject queries that reference unknown tables or columns with a clear error.

### 3. Test Suite
- **Unit tests**: parser correctness; per-operator behaviour on hand-built tables (project ignores extra columns, filter keeps only matching rows, join produces the expected cartesian-product-with-condition).
- **End-to-end tests**: a small `Users`/`Orders` schema with a handful of rows and a few queries whose expected results you compute by hand.
- **Property-based tests**: invariants — `project xs . project ys = project (xs intersect ys)` (under set semantics; if your engine keeps duplicate rows, restate this as equality of *bags*, not lists, since row order isn't fixed); selecting on `True` returns the full table; an inner join with an always-`False` condition is empty.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
