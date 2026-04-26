# Architectural trajectory

The capabilities below are **not yet implemented in production** in the form described. They represent the architectural direction of the framework, informed by both prior research and the requirements of Graviola's existing users. Each is documented here so that current development decisions remain compatible with these directions.

The discipline applied to this section: a capability is described here only when its shape is clear enough that the team has chosen not to foreclose it through current design choices.

For **what ships today**, see [Capabilities today](capabilities-today.md).

---

## Schema evolution via lenses

Schemas evolve over the lifetime of an application. In Graviola's current deployments, this is handled either by classical migration scripts (where the application owns its database) or by manual rewriting of mapping configurations (where data is ingested from a versioned authority).

The architectural direction is to express version-to-version transformations as **bidirectional lenses** — small, composable, declarative documents that describe how to migrate data forward to a newer schema and, where possible, backward to an older one. This is a well-studied pattern; the closest existing implementation is [Project Cambria](https://www.inkandswitch.com/cambria/) from Ink & Switch.

In Graviola's intended model, each entity carries a `gra:version` property identifying the schema version under which it was authored. A consumer encountering an entity at a different version applies the appropriate lens chain at query time. The lens engine is an opt-in capability of an `AbstractDatastore` implementation, not a requirement.

Related glossary entries: [Lens](glossary.md#25-lens), [Entity version](glossary.md#22-entity-version), [Schema drift](glossary.md#24-schema-drift), [Lens-as-data](glossary.md#29-lens-as-data).

---

## Calculated fields

Some schema properties are best expressed as derivations rather than stored values: a person's full name from forename and surname; an aggregate computed across linked entities; a status flag derived from temporal conditions. The intended mechanism is a declarative formula language (HyperFormula-shaped), with each calculated field declaring its dependencies, its complexity class, and the resources it requires to evaluate.

The complexity and capability annotations matter because Graviola's deployment targets range from in-browser applications on commodity hardware to server-side processes with substantial compute. A calculated field that is acceptable on a server may be prohibitive in a browser; the runtime will choose between eager and lazy evaluation, or refuse to evaluate, based on the host's declared capabilities.

Related glossary entries: [Calculated field](glossary.md#41-calculated-field), [Capability context](glossary.md#47-capability-context), [IVM](glossary.md#44-incremental-view-maintenance-ivm).

---

## Signed states and authoritative value

For applications where the credibility of data matters — historical databases, cultural heritage catalogs, expert-curated reference works — the framework's intended trust model is built on **signed states**: cryptographically signed snapshots of an entity (or of a lens, or of a schema) attesting that a named party vouches for its correctness at a moment in time. Multiple signatures, weighted by the trust graph among signers, contribute to a computed *authoritative value* used to surface plausible versus contested entries.

The cryptographic substrate is intended to be the W3C [Verifiable Credentials Data Model](https://www.w3.org/TR/vc-data-model/).

Related glossary entries: [Signed state](glossary.md#54-signed-state), [Authoritative value](glossary.md#55-authoritative-value).

---

## Schema and lens as syncable data

Graviola's existing storage layer treats data as documents. The intended extension is to treat **schemas and lenses themselves as documents** — JSON-LD documents with stable `@id`s, syncing through the same transport (Yjs, Solid, SPARQL endpoints) as application data. This generalizes a pattern observed in field deployments where domain experts authored schemas via JSON Forms-based designers and distributed them peer-to-peer alongside the data.

When schemas, lenses, and data all flow through one transport, signing extends uniformly to all three.

Related glossary entries: [Schema-as-data](glossary.md#11-schema-as-data), [Federated sync layer](glossary.md#13-federated-sync-layer).

---

## See also

- [Deployment scenarios](deployment-scenarios.md) — where trajectory topics intersect real deployments.
- [Glossary](glossary.md) — open questions at the frontier ([Cross-version calc sync](glossary.md#71-cross-version-calc-sync), etc.).
- [Further reading](further-reading.md).
