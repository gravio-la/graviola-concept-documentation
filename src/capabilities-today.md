# Capabilities today

This chapter describes Graviola **as it exists in production today**. Directions that are not yet implemented in the form described are kept in [Architectural trajectory](trajectory.md).

---

## Schema-driven CRUD

Given a JSON Schema definition with `@id` and `@type` semantics, Graviola provides:

- **`GenericForm`** — a top-level component that, given a schema and an entity IRI, generates a form, loads the entity from the configured store, manages dirty state and validation, and writes changes back. No per-entity-type code is required.
- **`SemanticJsonForm`** — the lower-level component, used when explicit control over schema, UI schema, or data flow is needed.
- **CRUD hooks** — `useFormData`, `useFormEditor`, `useCRUDWithQueryClient`, integrated with TanStack Query for caching and invalidation.

The CRUD pipeline translates JSON Schema definitions into store-appropriate operations. For SPARQL backends, this means generating CONSTRUCT queries for reads and INSERT/DELETE patterns for writes; for Prisma backends, it means typed ORM operations; for REST, configurable endpoint patterns.

Whether JSON Schema (and companion UI or mapping files) are **authored by hand** or **generated in the application build** — for example from [LinkML](linkml-authoring.md) — does not change this pipeline: Graviola consumes the same outputs at runtime.

---

## Form rendering

Graviola uses [JSON Forms](https://jsonforms.io/) as its UI rendering substrate. The framework ships a renderer registry covering:

- Standard field types (text, number, date, boolean, enum)
- Linked-data-aware renderers (entity pickers that query the configured store, authority lookup widgets)
- Layout renderers (grids, tabs, sections)
- Specialized renderers for color input, MapLibre GL maps, and Markdown editing

Renderers are registered once and dispatched by schema shape rather than by entity type. Adding a new entity type to a Graviola application typically requires no new renderer code.

---

## SemanticTable

`SemanticTable` is a schema-driven table component providing:

- Pagination, sorting, and filtering against the configured store
- Soft-delete (move to trash, restore from trash)
- CSV export
- Column visibility configuration
- Row selection and inline editing hooks

The table derives its columns and filters from the same JSON Schema used by the forms, so a change in the schema propagates to both surfaces without intervention.

---

## Declarative authority mapping

Graviola's mapping layer is the production-tested mechanism for transforming records from external authority sources into the application's local data model. Mappings are written as JSON-LD-flavored declarative documents, not code. Each mapping entry pairs a source path (JSONPath against the authority response) with a target path in the local schema, optionally invoking a named **strategy** for non-trivial transformations.

The strategy catalog includes operations for concatenation, first-match selection, date-string-to-integer conversion, entity creation with authoritative back-links, template substitution, and recursion into nested mappings. The catalog is extensible, and new strategies can be added without modifying the mapping engine.

This layer is currently used for ingestion from Wikidata, GND, and DBpedia in cultural heritage applications. It is documented and has been refined across multiple deployments.

---

## Storage backends

Concrete `AbstractDatastore` implementations available today:

| Backend | Status | Typical use |
|---|---|---|
| In-browser Oxigraph (WebAssembly) | Production | Local-first applications, no-server deployments |
| Remote SPARQL endpoint | Production | Federated data, existing institutional triple stores |
| Prisma (PostgreSQL, SQLite, others) | Production | Internal tools, classical web applications |
| REST API | Production | Integration with existing HTTP services |
| In-memory (Zustand) | Production | Testing, prototyping |

The SPARQL backend supports multiple dialects (standard SPARQL 1.1, Oxigraph, Blazegraph, Allegro) selectable per deployment.

---

## Browser/server symmetry

Graviola's foundation and schema-to-query layers are constrained to be free of React, MUI, or any browser-only dependency. This constraint is enforced because the same packages are consumed by command-line tools (`@graviola/edb-cli`) and a REST API server (`apps/edb-api`) running on Bun. The translation from JSON Schema to SPARQL, the graph-to-JSON extraction, and the data-mapping engine all run identically in browser and server environments.

This symmetry is a load-bearing property of Graviola's design and shapes how new capabilities are added.

---

## See also

- [Architecture and data flow](architecture.md) — how these pieces connect.
- [LinkML as an authoring source for schemas](linkml-authoring.md) — optional build-time generation of today's artifacts.
- [Glossary](glossary.md) — [AbstractDatastore](glossary.md#66-abstractdatastore), [Declarative mapping](glossary.md#31-declarative-mapping), [JSON Forms](glossary.md#65-json-forms).
- [Architectural trajectory](trajectory.md) — planned extensions (lenses, calcs, signing) *not* guaranteed by this chapter.
