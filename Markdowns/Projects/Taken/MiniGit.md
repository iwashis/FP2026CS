# MiniGit: A Tiny Content-Addressed Version-Control System

## Motivation

Git is one of the most important pieces of software of the last twenty years, and almost every developer interacts with it daily — yet very few have a clear mental model of what is actually happening when they run `git commit`. The pleasant surprise is that the *core* of Git is small and elegant: every blob, tree, and commit is stored under a hash of its contents (so identical content is automatically deduplicated), and a "branch" is just a pointer to a commit. The plumbing commands that real Git exposes (`git hash-object`, `git cat-file`, `git update-ref`) make this directly visible. This project is a stripped-down Git: a content-addressed object store plus the porcelain commands needed to track a working tree on top of it.

## Project Overview
This project implements a tiny version-control system in the spirit of Git. The user works in a directory; running the tool's commands tracks changes, records snapshots as commits, and walks the history. The on-disk layout deliberately mirrors Git's: a content-addressed object store, plus refs that point into it.

## Key Goals
1. **Object Store**: Implement a content-addressed store on disk with three object kinds — blob (file contents), tree (a directory listing), and commit (parent + tree + message + author/date).
2. **Working-Tree Commands**: `init`, `add`, `commit`, `log`, `checkout` (or your subset of those), wired up against the object store.
3. **Test Suite**: Cover the object store, individual commands, and a handful of end-to-end scenarios.
4. **Branches & Diff (stretch)**: Add named branches, `branch`/`switch`-style commands, and a textual diff between two commits.

## Suggested Core Data Types

A starting point — adapt to your design.

```haskell
-- Each object is identified by the hash of its contents.
type Hash = String

data Object
  = Blob   ByteString
  | Tree   [TreeEntry]
  | Commit CommitInfo
  | ...

data TreeEntry = TreeEntry
  { entryName :: FilePath
  , entryHash :: Hash
  , entryKind :: EntryKind        -- file vs. nested tree
  }

data EntryKind = File | Dir | ...

data CommitInfo = CommitInfo
  { commitTree    :: Hash
  , commitParent  :: Maybe Hash
  , commitAuthor  :: String
  , commitMessage :: String
  , commitTime    :: ...           -- POSIXTime, ZonedTime, your choice
  }
```

Use SHA-1 or SHA-256 for hashing — the standard library plus `cryptonite`/`SHA` covers either. The on-disk encoding of objects is your choice; the simplest is to write each one as a file under `.minigit/objects/<hash>` containing a tagged serialisation of the body.

## Example

```
$ minigit init
Initialised empty repository in .minigit/

$ echo "hello" > greeting.txt
$ minigit add greeting.txt
$ minigit commit -m "first commit"
[main abcdef] first commit

$ echo "world" >> greeting.txt
$ minigit add greeting.txt
$ minigit commit -m "second commit"
[main 123456] second commit

$ minigit log
123456  second commit
abcdef  first commit
```

## Implementation Components

### 1. Object Store
- Provide functions to write an object (returning its hash) and to read an object back by hash.
- Define a deterministic serialisation for blobs, trees, and commits — the same input must always hash to the same output.
- Lay the store out on disk under `.minigit/` so an external observer can poke around.

### 2. Working-Tree Commands
- `init` creates the `.minigit/` skeleton.
- `add <path>` stages a file (writes a blob and updates the index).
- `commit -m <msg>` writes a tree from the index, writes a commit with the current branch's tip as parent, and advances the branch pointer.
- `log` walks back from the current branch's tip following parents.
- `checkout <commit>` restores the working tree to the state recorded in that commit (with sensible behaviour when local changes would be overwritten — bail out, do not silently lose work).

### 3. Test Suite
- **Unit tests**: hashing is content-determined (same blob → same hash); writing then reading an object round-trips it; tree serialisation is canonical (entries in a fixed order).
- **End-to-end tests**: a scripted session like the one above, run in a temp directory, with the resulting `.minigit/` inspected; that `checkout`-ing back to an earlier commit restores the older file contents byte-for-byte.
- **Property-based tests**: invariants — for any sequence of `add`/`commit` operations, every tree referenced by a commit exists in the object store; identical file contents always produce the same blob hash.

## Submission

Commit the completed project to your personal course repository — the same repo you use for homework — in a `project/` folder next to the existing `homeworks/` folder.
