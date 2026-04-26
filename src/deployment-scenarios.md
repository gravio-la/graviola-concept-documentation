# Deployment scenarios

The scenarios below describe shapes of deployment that Graviola has supported or is designed to support. Each scenario indicates which capabilities are involved and which are drawn from [Architectural trajectory](trajectory.md) rather than current production.

---

## Cultural heritage and library catalogs

The original driver of Graviola's design. A cataloging team needs to enter records about books, persons, places, exhibitions, or works, with frequent reference to external authorities (GND for German-language records, Wikidata for cross-domain links, VIAF for international author identifiers). The data model is rich, evolves slowly, and must produce valid RDF Linked Data for publication.

Graviola serves this scenario today through:

- JSON Schema definitions with `@id` and `@type` semantics, enabling round-trip to RDF
- `GenericForm` for manual data entry, with linked-data-aware renderers for authority lookups
- `SemanticTable` for catalog browsing
- The declarative mapping layer for ingesting authority records into the local model
- A SPARQL endpoint as the storage backend, allowing the catalog to be queried as Linked Open Data

Trajectory capabilities relevant to this scenario: signed states for expert-curated records; lens-based migration as the schema evolves across project lifetimes.

---

## Offline-first field deployments

A team operates in an environment with intermittent or absent connectivity — a research vessel, a field site, a remote installation. Multiple devices need to share a working data model and current data, without depending on a central server.

Graviola has been deployed in this configuration with a JSON Forms-based schema designer producing schemas at runtime, distributed alongside the data over a Yjs-based WebRTC transport. The application operates entirely offline; reconnection synchronizes both schema and data changes between peers.

The current implementation handles a single shared schema version per peer group. The trajectory direction extends this to peer-specific schema versions reconciled via lens application — a capability whose architectural shape is clear but whose implementation has not been completed.

---

## Privacy-sensitive data collection

An application handles data whose disclosure to a server operator is unacceptable: personal records under regulatory protection, sensitive interview transcripts, internal information that must not be visible to infrastructure providers. The deployment requires that the server function as a transport and storage layer only, never gaining access to plaintext.

Graviola's browser/server symmetry is the load-bearing property here. The schema, the form, the validation, and the encryption all run in the browser before data leaves the device. Servers handle ciphertext. The same Graviola components used for non-sensitive applications operate in this mode without modification, given the appropriate `AbstractDatastore` implementation.

---

## Internal tools with classical backends

Not every Graviola deployment requires the federated, peer-to-peer, schema-evolving model. The framework is also used as a productivity layer over conventional Prisma-backed PostgreSQL or MongoDB databases, where the team owns the model and uses standard migration tooling.

In this configuration, Graviola provides JSON Schema-driven forms, tables, and validation over a Prisma-managed store. Schema evolution is handled by Prisma migrations in the conventional way; the lens engine is not enabled. This deployment shape is an intentional first-class case, not a downgrade.

---

## Authority-linked reference databases

A reference database — biographical, geographical, terminological — needs to maintain links between local entities and one or more external authorities, allowing data to be re-fetched or cross-referenced without losing local annotations.

Graviola provides this through its primary/secondary IRI distinction: each local entity carries a canonical local IRI and any number of `sameAs` links to authority entries. The mapping layer governs how authority data is transformed into local schema shape on initial ingestion; subsequent updates can re-fetch from the authority and merge changes against the local annotations.

Trajectory capabilities relevant here: signed states allowing experts to annotate or correct authority-derived data with an audit trail.

---

## See also

- [Architecture and data flow](architecture.md) — layers behind these scenarios.
- [Glossary](glossary.md) — [Local-first](glossary.md#61-local-first), [Federated sync layer](glossary.md#13-federated-sync-layer), [Primary IRI / Secondary IRI](glossary.md#53-primary-iri--secondary-iri).
