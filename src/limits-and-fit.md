# Limits, fit, and evaluation

---

## What Graviola is not

Equally important to scope is what Graviola does not attempt:

- **Graviola is not a database**. It is a layer over storage backends. The choice of triple store, relational database, or REST service is the application's, not the framework's.
- **Graviola is not a reasoner**. The conceptual model is reasoning-shaped (property-driven class derivation, transitive `sameAs`), but inference, where required, is performed by the underlying store or by application code. The framework does not ship an OWL reasoner.
- **Graviola is not a CMS**. There is no built-in role model, publication workflow, asset pipeline, or page composition system. Applications building such features do so on top of Graviola's CRUD primitives.
- **Graviola is not a complete frontend stack**. It provides components for forms and tables, but page routing, application shell, theming, and authentication are application concerns. The example application (`apps/testapp`) demonstrates one way to compose these but does not prescribe.
- **Graviola is not a substitute for a hand-tuned schema** in performance-critical scenarios. Schema-driven query generation introduces overhead. For high-throughput services with stable schemas, Graviola is appropriate at the application layer but should not be assumed performant in the inner loop of a search engine or analytics system.

---

## Evaluating Graviola for a project

The framework is most appropriate when the following hold:

- The application is built around a domain data model with multiple related entity types.
- The data model is expected to evolve, or already exists in multiple representations across data sources.
- Forms and tables for these entity types would otherwise need to be hand-written and maintained.
- JSON Schema is acceptable as the central description language.
- The deployment can accept TypeScript on the application side.

The framework is less appropriate when:

- The data model is fixed, simple, and unlikely to change.
- The application is dominated by a single bespoke interaction surface (a custom editor, a domain-specific visualization) rather than CRUD over structured records.
- The existing technology stack is not JavaScript/TypeScript and crossing that boundary is undesirable.

For teams considering Graviola, the recommended starting point is `apps/testapp` in the framework's monorepo. It is a minimal Vite + React application demonstrating `GenericForm` over a small schema with nested entities. The application is approximately one screen of code and exercises the core CRUD path end-to-end.

---

## Repository and reference

The framework is published at [github.com/gravio-la/graviola-framework](https://github.com/gravio-la/graviola-framework). The monorepo contains approximately fifty packages under the `@graviola/` scope, organized by the layer architecture described in [Architecture and data flow](architecture.md). The canonical example application is `apps/testapp`.

A separate [Glossary](glossary.md) defines the framework's terminology, with references to the literature and prior projects underlying each concept.

---

## See also

- [What Graviola is](what-graviola-is.md) — the positive definition.
- [Architectural trajectory](trajectory.md) — future direction vs today's guarantees.
- [Further reading](further-reading.md) — external papers and tools.
