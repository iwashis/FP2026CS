# Haskell Setup via GHCup

## What is GHCup?

[GHCup](https://www.haskell.org/ghcup/) is the recommended installer for the Haskell toolchain. It manages:

- **GHC** — the Glasgow Haskell Compiler
- **Cabal** — the build tool and package manager
- **Stack** — an alternative build tool (opinionated, project-centric)
- **HLS** — Haskell Language Server (IDE support)

---

## Installing GHCup

### macOS / Linux / WSL

Run the bootstrap script:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
```

Follow the prompts. GHCup will ask whether to install GHC, Cabal, Stack, and HLS. You can say yes to all during setup, or manage them individually later.

After installation, reload your shell (or open a new terminal), then verify:

```sh
ghcup --version
ghc --version
```

### Windows

Download and run the GHCup installer from the [official site](https://www.haskell.org/ghcup/). It installs everything including MSYS2.

---

## Managing the Toolchain

GHCup uses a TUI (text-based UI) for interactive management:

```sh
ghcup tui
```

Or use CLI commands directly:

```sh
ghcup list              # show available versions of each tool
ghcup install ghc 9.12.2 # install a specific GHC version
ghcup set ghc 9.12.2     # set it as the active version
ghcup install cabal     # install latest Cabal
ghcup install stack     # install Stack
ghcup install hls       # install Haskell Language Server
```

---

## Recommended Versions (2026CS)

This course uses the following versions (current instructor setup as of February 2026):

| Tool  | Version  | Notes                        |
|-------|----------|------------------------------|
| GHCup | 0.1.50.2 | latest, recommended          |
| GHC   | 9.12.2   | active; hls-powered          |
| Cabal | 3.10.3.0 | active                       |
| Stack | 3.7.1    | active, recommended          |
| HLS   | 2.13.0.0 | active, latest, recommended  |

Stack manages its own GHC per project via `stack.yaml`, so the active global GHC version is less critical when using Stack.

---

## Stack Workflow (used in this course)

Stack manages GHC versions per project, so you may not need to set a global GHC version. The key commands:

```sh
stack new my-project    # create a new project from a template
stack build             # compile the project
stack run               # run the executable
stack ghci              # open an interactive REPL for the project
stack test              # run tests
```

Inside an existing project directory, `stack build` will automatically download and use the GHC version pinned in `stack.yaml`.

---

## Editor Setup

### VS Code

Install the **Haskell** extension (by Haskell.org). It uses HLS automatically if it is installed via GHCup.

### Neovim / Emacs

Configure your LSP client to use `haskell-language-server-wrapper` as the language server binary.

---

## Quick Sanity Check

After setup, open a terminal and try:

```sh
ghci
```

You should drop into an interactive Haskell prompt. Type `:quit` to exit.

```haskell
Prelude> 2 + 2
4
Prelude> :quit
```
