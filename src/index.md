# Introduction

This book is **conceptual documentation** for [Graviola](https://github.com/gravio-la/graviola-framework): a schema-driven semantic CRUD framework used across several projects while it matures. It is written for **developers** who are comfortable with architecture, integration, and data modeling—not for end users.

## What you will find here

- **Problem framing** — why federated, multi-source, and evolving models strain conventional tooling ([The shape of a federated application](federated-application.md)).
- **What Graviola is today** — JSON Schema as the runtime contract for the model, storage-agnostic backends, forms, tables, and declarative authority mapping ([What Graviola is](what-graviola-is.md), [Capabilities today](capabilities-today.md)).
- **How it is structured** — layers and read/write data flow ([Architecture and data flow](architecture.md)).
- **Where it runs** — representative deployment shapes ([Deployment scenarios](deployment-scenarios.md)).
- **Honest scope** — non-goals and when *not* to reach for Graviola ([Limits, fit, and evaluation](limits-and-fit.md)).
- **Where it is heading** — architectural trajectory, clearly separated from production guarantees ([Architectural trajectory](trajectory.md)).
- **Authoring upstream of JSON Schema** — optional build-time modeling (for example [LinkML as an authoring source for schemas](linkml-authoring.md)) that still emits the JSON Schema, UI schema, and mapping artifacts Graviola consumes at runtime.
- **Shared vocabulary** — terms, literature, and open questions ([Glossary](glossary.md), [Further reading](further-reading.md)).

## What this book is *not*

- **Not** the full framework API or package-by-package reference (that lives in the monorepo and will grow in separate technical docs).
- **Not** a Storybook substitute: UI components and interactive examples belong in Storybook; this book points there when useful.
- **Not** a single customer narrative: examples are illustrative across domains (heritage, internal tools, offline-first, etc.).

## How to read progressively

1. Start with [The shape of a federated application](federated-application.md) if the *problem* is new.
2. Read [What Graviola is](what-graviola-is.md) and [Capabilities today](capabilities-today.md) for the **current** product story.
3. Use [Architecture and data flow](architecture.md) as the map of layers and pipelines.
4. Treat [Architectural trajectory](trajectory.md) and the [Glossary](glossary.md) as **deepening** material—optional until you need precision on lenses, sync, trust, etc.
5. If authoring fragmentation (many files per model) matters to your team, read [LinkML as an authoring source for schemas](linkml-authoring.md) for a build-time pattern that leaves Graviola's runtime unchanged.

Canonical **seed** sources for this edition live under [`seed/`](https://github.com/gravio-la/graviola-conceptual-documentation/tree/main/seed) in the same repository; chapters here are the book-shaped rearrangement of that content.

## See also

- [Graviola framework monorepo](https://github.com/gravio-la/graviola-framework) — code, `apps/testapp`, packages under `@graviola/*`.
- [Glossary](glossary.md) — definitions and references in one place.
