# What Graviola is

## A semantic CRUD framework for schema-driven applications

---

## Overview

Graviola is a TypeScript framework for building applications whose central abstraction **at runtime** is a **JSON Schema** (or Zod-derived JSON Schema) describing the shape of domain entities. Teams may maintain that schema by hand or generate it upstream in the build (for one documented pattern, see [LinkML as an authoring source for schemas](linkml-authoring.md)); the framework consumes the same artifact shapes either way. From the schema definition Graviola generates and operates: forms for creating and editing entities, tables for browsing them, queries against the storage backend, and validation of the data flowing in and out. The same schema drives the user interface, the persistence layer, and the integration layer.

The framework is **storage-agnostic at its core**. The same schemas, forms, and tables operate against an in-browser SPARQL store (Oxigraph compiled to WebAssembly), a remote SPARQL endpoint, a Prisma-backed relational database, a REST API, or an in-memory store for testing. This is not abstraction for its own sake: Graviola has been deployed in each of these configurations across different projects.

Graviola also includes a **declarative mapping layer** for ingesting structured data from external authority sources — Wikidata, the German Integrated Authority File (GND), DBpedia — into the application's local data model. This layer is the framework's most mature non-CRUD subsystem and is currently the primary mechanism by which Graviola handles cross-source data integration.

The framework is published as a monorepo of approximately fifty packages under the `@graviola/` scope, designed to be consumed individually rather than as a bundle.

---

## Why Graviola exists

A recurring pattern in domain-specific applications — cultural heritage catalogs, scientific data collection, internal tooling, knowledge management — is the gap between two competing needs:

- The data model is **rich and evolving**: nested entities, references between records, multilingual fields, links to external authorities, schema changes over the lifetime of the project.
- The development resources are **bounded**: the team cannot afford to hand-write a bespoke form, table, validation rule, and query for every entity type, and cannot afford to rewrite them every time the schema changes.

The conventional answers to this gap each fall short for one of Graviola's core use cases. ORM-driven scaffolding (Django admin, Rails forms, etc.) assumes a relational backend and a single deployed schema. Generic form libraries solve the form problem but not the persistence or query problem. Hand-rolled CRUD abstractions accumulate domain logic and resist reuse across projects.

Graviola's response is to take **JSON Schema as the runtime single source of truth** (Zod is supported where JSON Schema is derived from it) and derive everything else from it: the form (via JSON Forms), the table (via material-react-table with Graviola wrappers), the query (via the framework's schema-to-SPARQL translator or the equivalent for other backends), and the validation (via Ajv, against the same schema). The schema travels with the data; tooling built on Graviola can be ported between storage backends with minimal change.

---

## See also

- [The shape of a federated application](federated-application.md) — the problem this design responds to.
- [Capabilities today](capabilities-today.md) — concrete production features.
- [Architecture and data flow](architecture.md) — layers and pipelines.
- [LinkML as an authoring source for schemas](linkml-authoring.md) — optional build-time modeling upstream of JSON Schema.
- [Graviola framework monorepo](https://github.com/gravio-la/graviola-framework) — source and `apps/testapp`.
