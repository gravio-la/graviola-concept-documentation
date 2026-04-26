# Graviola conceptual documentation

Conceptual architecture book for [Graviola](https://github.com/gravio-la/graviola-framework), built with [mdBook](https://rust-lang.github.io/mdBook/).

## Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled (`experimental-features = nix-command flakes`).

## Develop

```bash
nix develop
mdbook-mermaid install   # once per clone: vendors mermaid.min.js (gitignored)
mdbook serve --open
```

Build only:

```bash
nix develop
mdbook-mermaid install && mdbook build
```

Same build as CI (non-interactive; do not use bare `nix develop` in scripts — it may skip work without a TTY):

```bash
nix develop --command bash -euo pipefail -c 'mdbook-mermaid install && mdbook build'
```

## Content

- **Book sources:** [`src/`](src/)
- **Seed drafts** (reference / upstream wording): [`seed/`](seed/)
