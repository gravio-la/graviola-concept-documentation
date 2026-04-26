# Graviola Glossary

> **Navigation:** This glossary deepens vocabulary used across the book. For the product overview first, see [What Graviola is](what-graviola-is.md) and [Capabilities today](capabilities-today.md). For future direction, see [Architectural trajectory](trajectory.md). For unresolved design questions that span multiple terms, see [Outlook and open questions](outlook-and-open-questions.md).

A working vocabulary for the Graviola framework: federated, schema-evolving, local-first semantic data infrastructure. This glossary names the concepts Graviola relies on, points at the literature and prior projects that defined or refined each one, and gives short examples grounded in Graviola's actual use cases (cultural heritage, personal information management, offline-first field deployments).

The glossary is organized in layers, working roughly from foundations outward. Cross-references between entries use **bold** on first mention. Each entry has a short definition, an *Example* where one helps, *See also* cross-references, and *References* with links to literature or prior projects.

A note on optionality. Graviola is built from small, composable libraries. Most of the machinery described here — lenses, IVM, signed states, reasoning — is *optional*. Many Graviola applications use a single fixed schema with classical migrations (see [Classical Migration](#63-classical-migration)) and never touch the lens engine; others use only the UI dispatch layer over a Prisma-backed PostgreSQL or MongoDB store. The architecture is designed so that none of these advanced concepts becomes a blocker for the simple cases.

---

## 1. Foundations

### 1.1 Schema-as-Data
Schemas (LinkML, JSON Schema, SHACL shapes) are not ambient configuration baked into deploys but first-class documents with `@id`s that travel through the same sync layer as the data they describe. A consequence: schemas can be authored, versioned, signed, and migrated by the same machinery as any other entity.

*Example:* On a ship with intermittent connectivity, a domain expert authors a JSON Schema via JSON Forms. The schema syncs across peers via Yjs/WebRTC alongside the data conforming to it.

*See also:* [Lens-as-Data](#29-lens-as-data), [Federated Sync Layer](#13-federated-sync-layer), [Entity Version](#22-entity-version).

*References:*
- [Solid Project](https://solidproject.org/)
- [LinkML](https://linkml.io/)
- [JSON-LD 1.1](https://www.w3.org/TR/json-ld11/)

---

### 1.2 Structural Dispatch
The architectural principle that behavior — UI rendering, mapping, validation, calculation, lens application — is bound to the *shape* declared by a schema (or to a property carried by an entity), not to a nominal type or class. This single pattern recurs at every layer of Graviola and is what allows components to survive [Schema Drift](#24-schema-drift) without code changes.

*Example:* JSON Forms resolves a renderer for `{type: "string", format: "date"}` regardless of which entity type contains the field. The same principle drives lens dispatch by [Entity Version](#22-entity-version) and class derivation by property (see [Derived Versioned Class](#23-derived-versioned-class)).

*See also:* [JSON Forms](#65-json-forms), [Declarative Mapping](#31-declarative-mapping).

*References:*
- [JSON Forms](https://jsonforms.io/)

---

### 1.3 Federated Sync Layer
The transport-and-replication substrate (in Graviola: Yjs, optionally over WebRTC, WebSocket, or Solid Pods) that moves both data and schema documents between peers without assuming a central authority. The sync layer makes no semantic decisions; it only guarantees eventual consistency of opaque documents.

*Example:* Ship deployment where servers are pure relays and have no plaintext access; peers sync end-to-end-encrypted documents and resolve schema versions locally on reconnection.

*References:*
- [Yjs](https://docs.yjs.dev/)
- [Local-first software](https://www.inkandswitch.com/local-first/) (Kleppmann, Wiggins, van Hardenberg, McGranaghan, Ink & Switch, 2019)
- Shapiro, Preguiça, Baquero, Zawirski, *"Conflict-Free Replicated Data Types"* (2011)

---

### 1.4 Reasoning-Compatible, Reasoner-Optional
Graviola's conceptual model is shaped by description-logic and rule-based reasoning (property-driven class derivation, entailment, transitive sameAs), but Graviola does not ship a reasoner. Where the underlying datastore supports reasoning (e.g., a triple store with OWL RL or a SHACL-AF engine), derivations can be materialized; where it does not, the same derivations can be computed at extraction time by Graviola's pipeline. Both paths produce the same query semantics for the cases Graviola cares about.

*See also:* [Derived Versioned Class](#23-derived-versioned-class).

*References:*
- [W3C OWL 2 RL Profile](https://www.w3.org/TR/owl2-profiles/#OWL_2_RL)
- [SHACL Advanced Features](https://www.w3.org/TR/shacl-af/)

---

## 2. Schema Evolution & Versioning

### 2.1 Schema Version
A specific, content-addressable state of a schema document, identified by an `@id` and typically a semver tag. Schema versions are themselves documents and live in the same sync layer as data (see [Schema-as-Data](#11-schema-as-data)).

*See also:* [Entity Version](#22-entity-version), [Lens](#25-lens).

---

### 2.2 Entity Version
A property — `gra:version` or equivalent — carried by each named entity, recording which [Schema Version](#21-schema-version) the entity was authored under. Version is a property of the *entity*, not (only) of its container or store. This is what makes mixed-version data within a single store the normal case rather than an exception: a query for entities of a given conceptual type returns instances of all versions, and refinements by version are just property filters.

*Example:* A query against a federated person index returns `{@id: ..., @type: ex:Person, gra:version: "0.3.2", name: ...}` and `{@id: ..., @type: ex:Person, gra:version: "0.4.5", forename: ..., surname: ...}` side by side. The consumer's tool decides whether to apply a [Lens](#25-lens) based on the `gra:version` it sees.

*See also:* [Derived Versioned Class](#23-derived-versioned-class), [Schema Drift](#24-schema-drift).

---

### 2.3 Derived Versioned Class
A conceptual subclass of an entity type, derived at runtime by the value of a property — most importantly [Entity Version](#22-entity-version), but the pattern is general. `ex:Person_V2_3_0` is the (conceptual) subclass of `ex:Person` whose members carry `gra:version "2.3.0"`. Such derived classes can drive query refinement, dispatch in the graph-to-JSON extraction pipeline, and lens selection.

This is the same pattern as deriving `ex:Author` from `ex:Person` by the presence of an authored work, or `ex:SignedDocument` from `ex:Document` by the presence of a [Signed State](#54-signed-state) — property-driven subclass derivation, well-understood in description logics. Graviola applies it to versioning.

*Example:* The graph-to-JSON pipeline for a visualization plugin declared at `V0_3_8` selects entities that are either `ex:Person_V0_3_8` directly or are reachable via lens composition from another version. The selection is expressed as a query over `gra:version`, not as a separate negotiation step.

*See also:* [Structural Dispatch](#12-structural-dispatch), [Reasoning-Compatible, Reasoner-Optional](#14-reasoning-compatible-reasoner-optional).

*References:*
- Baader, Calvanese, McGuinness, Nardi, Patel-Schneider, *The Description Logic Handbook* (Cambridge University Press, 2003) — for the general theory of property-driven class derivation.

---

### 2.4 Schema Drift
The condition in which entities within a federation — or within a single store — carry different values of [Entity Version](#22-entity-version) for the same conceptual type. Drift is the normal case in Graviola, not an error to recover from. Tools handle drift either by applying a [Lens](#25-lens) chain, by restricting their query to a specific [Derived Versioned Class](#23-derived-versioned-class), or by falling back to [Classical Migration](#63-classical-migration) where the application owns the model.

*References:*
- [COPE / Edapt](https://www.eclipse.org/edapt/) (Herrmannsdoerfer et al.)
- Curino, Moon, Zaniolo, *"Graceful database schema evolution: the PRISM workbench"* (VLDB 2008).

---

### 2.5 Lens
A pair of transformations between two schema versions (or between two parallel schemas) consisting of a forward function (`get`) and a reverse function (`put`). Lenses are Graviola's primary mechanism for handling [Schema Drift](#24-schema-drift). The lens engine is an *optional, pluggable component* — a concrete [AbstractDatastore](#66-abstractdatastore) implementation may or may not enable it, and many Graviola applications run without it.

*Example:* A lens from `Person_V1` (single `name` field) to `Person_V2` (`forename`, `surname`) defines how to split forward and how to recombine backward.

*See also:* [Asymmetric Lens](#26-asymmetric-lens), [Symmetric Lens](#27-symmetric-lens), [Lens Law](#28-lens-law), [Lens Composition](#210-lens-composition).

*References:*
- Foster, Greenwald, Moore, Pierce, Schmitt, [*"Combinators for Bidirectional Tree Transformations"*](https://www.cis.upenn.edu/~bcpierce/papers/lenses-toplas-final.pdf) (TOPLAS 2007).
- [Project Cambria](https://www.inkandswitch.com/cambria/) (Litt, van Hardenberg et al., Ink & Switch).

---

### 2.6 Asymmetric Lens
A lens where one side is canonical and the other is a view. The reverse direction reconstructs the source from the view plus the original source. Most version-pair migrations are asymmetric.

---

### 2.7 Symmetric Lens
A lens where neither side is a strict view of the other; both sides may hold information the other lacks. Necessary for cross-vocabulary alignment (e.g., Graviola's local model ↔ Wikidata) where each side has fields the other doesn't.

*References:*
- Hofmann, Pierce, Wagner, [*"Symmetric Lenses"*](https://www.cis.upenn.edu/~bcpierce/papers/symmetric-lenses.pdf) (POPL 2011).

---

### 2.8 Lens Law
A property a well-behaved lens must satisfy. The three canonical laws:

- **GetPut:** getting a view and putting it back unchanged yields the original source.
- **PutGet:** putting a view, then getting, yields what was put.
- **PutPut:** putting twice equals putting once with the latest value (very well-behaved lenses only).

Lenses that fail PutGet are [Lossy](#213-lossy-lens) and require [Witness Preservation](#214-witness-preservation) to round-trip safely.

---

### 2.9 Lens-as-Data
Lenses are themselves serializable JSON-LD documents with `@id`s, syncing through the same [Federated Sync Layer](#13-federated-sync-layer) as schemas and data. A lens can be authored, versioned, and signed independently of code.

*Example:* A historian signs a lens migrating heritage `Person_V1 → Person_V2`, vouching that the split of `name` into `forename`/`surname` was performed correctly for their corpus. The signature itself is a [Signed State](#54-signed-state) over the lens document.

*References:*
- [Project Cambria](https://www.inkandswitch.com/cambria/).

---

### 2.10 Lens Composition
The act of chaining lenses (`A→B`, `B→C`, `C→D`) into a single lens (`A→D`). Composition is associative; well-behavedness composes. In Graviola, a peer encountering data at `V0_3_2` while running `V0_4_5` assembles the migration chain by composition.

*See also:* [Lens Fusion](#211-lens-fusion).

---

### 2.11 Lens Fusion
Static algebraic simplification of a composed lens chain before execution: a `rename` followed by a `rename` of the same field collapses; an `add` followed by a `remove` cancels. Graviola's "compile to fast runtime struct" step is fusion, not codegen.

*References:*
- Wadler, [*"Deforestation: transforming programs to eliminate trees"*](https://homepages.inf.ed.ac.uk/wadler/papers/deforest/deforest.ps) (1990) — the foundational fusion technique.
- Cambria implements light fusion in practice.

---

### 2.12 Lens Operator Catalog
The fixed, small set of lens primitives from which all migrations are built. Cambria's catalog: `rename`, `hoist`, `plunge`, `wrap`, `head`, `add`, `remove`. Graviola's catalog will likely overlap heavily; the design question is granularity (more primitives = more fusion opportunities; fewer = simpler authoring).

---

### 2.13 Lossy Lens
A lens whose forward direction discards information that the reverse direction cannot recover from the view alone. Splitting `name → (forename, surname)` is lossy in reverse if the original whitespace, ordering, or particle handling matters.

*See also:* [Witness Preservation](#214-witness-preservation).

---

### 2.14 Witness Preservation
The technique of carrying a small companion record alongside migrated data that records what would otherwise be lost. The reverse lens consults the witness when reconstructing the source.

*Example:* Forward migration of `"van der Berg, Jan"` to `{forename: "Jan", surname: "van der Berg"}` emits a witness `{originalName: "van der Berg, Jan", splitStrategy: "comma-first"}`.

---

## 3. Mapping & Integration

### 3.1 Declarative Mapping
A JSON-LD-flavored DSL (Graviola's existing implementation) describing how to transform a source document into a target document via path-based source/target pairs and optional named [Mapping Strategies](#32-mapping-strategy). Used today primarily for ingesting authority data (GND, Wikidata, DBpedia) into the local model.

*Example:* The `wikidataPersonMapping` in Graviola's existing codebase: source `$.claims.P569[*].mainsnak.datavalue.value.time` → target `birthDate` via the `dateStringToSpecialInt` strategy.

*See also:* [Mapping Strategy](#32-mapping-strategy), [R2RML / RML](#36-r2rml--rml).

---

### 3.2 Mapping Strategy
A named, reusable transformation function (`concatenate`, `takeFirst`, `createEntity`, `dateStringToSpecialInt`, etc.) referenced by id from a [Declarative Mapping](#31-declarative-mapping) entry. Strategies receive the source value, the current target value, options, and a [Strategy Context](#33-strategy-context).

---

### 3.3 Strategy Context
The runtime environment passed to a mapping strategy: logger, IRI minter, authority access, secondary-IRI resolver, mapping table, and a `createDeeperContext` continuation for recursive mapping into nested entities.

---

### 3.4 Migration Lens vs. Cross-Source Query vs. Tool Projection
Three distinct mapping shapes that Graviola deliberately keeps separate:

- **Migration Lens:** between two versions of the same conceptual schema; bidirectional in principle; used for [Schema Drift](#24-schema-drift).
- **Cross-Source Query:** assembles a target document from one or more foreign sources (Wikidata, GND); typically forward-only; the existing Graviola [Declarative Mapping](#31-declarative-mapping) is this.
- **Tool Projection:** narrows a canonical entity to the fields a specific tool needs (e.g., a filelight visualization needs only `{path, size, parent}`); read-only; cheap.

Conflating these is a known failure mode of "universal data integration" projects.

---

### 3.5 Mediated Schema (LAV / GAV / GLAV)
The classical data-integration framings:

- **GAV (Global-as-View):** the global schema is defined as views over local sources. Adding a new source requires updating the global schema.
- **LAV (Local-as-View):** each local source is described as a view over the global schema. New sources join without touching the mediator. Best fit for Graviola.
- **GLAV:** a hybrid.

*References:*
- Lenzerini, [*"Data Integration: A Theoretical Perspective"*](https://dl.acm.org/doi/10.1145/543613.543644) (PODS 2002).

---

### 3.6 R2RML / RML
W3C-standard declarative mapping languages from relational (R2RML) or heterogeneous (RML) sources to RDF. Graviola's declarative mapping is a JSON-LD cousin of these, optimized for JSON Linked Data rather than serialization-level transformation.

*References:*
- [W3C R2RML Recommendation](https://www.w3.org/TR/r2rml/)
- [RML specification](https://rml.io/specs/rml/) (Ghent University)

---

### 3.7 Ontology Alignment
The (largely separate) problem of relating *concepts* across vocabularies, e.g., declaring that `schema:Person` and `foaf:Person` refer to the same class. Often expressed via `owl:sameAs`, `skos:exactMatch`, `skos:closeMatch`. Distinct from [Lens](#25-lens)-based migration: alignment is about identity of concepts, lenses are about transformation of representations.

*References:*
- Euzenat & Shvaiko, *Ontology Matching* (Springer, 2nd ed. 2013).

---

## 4. Calculated Fields & Reactivity

### 4.1 Calculated Field
A schema property whose value is derived from other fields by a declarative formula (HyperFormula-style or similar) rather than stored directly. Structurally equivalent to a one-directional lens (`get` only).

*Example:* `Person.fullName` calculated as `CONCAT(forename, " ", surname)`.

*See also:* [Stratification](#43-stratification), [Incremental View Maintenance](#44-incremental-view-maintenance-ivm).

*References:*
- [HyperFormula](https://hyperformula.handsontable.com/) — the formula engine Graviola's calc layer is patterned after.

---

### 4.2 Dependency Graph
The DAG of which calculated fields read which other fields. Used to determine recomputation order and to detect cycles.

---

### 4.3 Stratification
The ordering of a [Dependency Graph](#42-dependency-graph) into layers such that each layer depends only on previous layers. Required for safe evaluation of recursive or aggregate calculations in Datalog-style systems.

*References:*
- Abiteboul, Hull, Vianu, [*Foundations of Databases*](http://webdam.inria.fr/Alice/) (1995), ch. on stratified Datalog (free PDF available).
- [Gottlob, Datalog lecture notes](https://www.cs.ox.ac.uk/files/1019/gglecture8.pdf) (Oxford).

---

### 4.4 Incremental View Maintenance (IVM)
The technique of updating a derived view in response to input changes by computing only the delta, rather than re-evaluating from scratch. The performance backbone of any nontrivial [Calculated Field](#41-calculated-field) system at scale.

*References:*
- Gupta & Mumick, *"Maintenance of Materialized Views: Problems, Techniques, and Applications"* (IEEE Data Eng. Bulletin, 1995).
- [Differential Dataflow](https://github.com/TimelyDataflow/differential-dataflow) (McSherry et al.).

---

### 4.5 Differential Dataflow
The modern, industrial-grade form of IVM: a dataflow framework that maintains the result of arbitrarily complex relational and iterative computations under input changes, with provable efficiency. Likely overkill for in-browser Graviola but the right reference point for server-side calc-heavy workloads.

*References:*
- McSherry, Murray, Isaacs, Isard, [*"Differential Dataflow"*](https://www.cidrdb.org/cidr2013/Papers/CIDR13_Paper111.pdf) (CIDR 2013).
- [Materialize](https://materialize.com/).

---

### 4.6 Complexity Annotation
A declarative tag on a [Calculated Field](#41-calculated-field) describing its computational cost class (e.g., `O(1)`, `O(n)`, `O(n²)`) and optionally its memory footprint. Used by the runtime to choose between eager and lazy evaluation strategies and to decide whether the calc is admissible in a given [Capability Context](#47-capability-context).

---

### 4.7 Capability Context
The set of resources available to the current Graviola host: memory, persistence, network, server-presence, GPU, etc. Calculated fields and visualizations declare what they need; the runtime matches and either runs, degrades, or refuses.

*Example:* A calc that needs `{memory: "high", server: true}` is skipped on the encrypted-ship deployment and surfaced as "unavailable in this environment."

---

### 4.8 Calc-as-Pure-Derivation vs. Calc-as-Cached-Materialized-View
The unresolved design tension for federated calculated fields:

- **Pure derivation:** each peer recomputes locally from synced inputs. Clean, always consistent, potentially expensive.
- **Cached materialized view:** results are computed once (e.g., server-side) and synced; must invalidate correctly across version skew.

Genuinely an open problem when combined with [Schema Drift](#24-schema-drift) across CRDT-synced peers. See [Cross-version calc sync](outlook-and-open-questions.md#cross-version-calc-sync).

---

## 5. Authority, Trust, & Provenance

### 5.1 Authority
An external data source treated as a reference for entity identity and attributes (Wikidata, GND, DBpedia, VIAF). Graviola's [Declarative Mapping](#31-declarative-mapping) layer was built primarily to ingest from authorities into the local model.

---

### 5.2 Authoritative Link
A link from a local entity to its corresponding entry in an [Authority](#51-authority), typically expressed as `owl:sameAs` or via a domain-specific property. Enables later re-fetching, cross-referencing, and trust evaluation.

*Example:* A local `Person` with `sameAs http://www.wikidata.org/entity/Q42` for Douglas Adams.

---

### 5.3 Primary IRI / Secondary IRI
Graviola's distinction between the local canonical IRI of an entity (primary) and any external [Authority](#51-authority) IRI it is linked to (secondary). The `getPrimaryIRIBySecondaryIRI` resolver in the [Strategy Context](#33-strategy-context) mediates this.

---

### 5.4 Signed State
A cryptographically signed snapshot of an entity (or a subset of its fields, or a [Lens](#25-lens) document) attesting that a named party (historian, expert, institution) vouches for its correctness at a moment in time. Multiple signatures on the same data raise its [Authoritative Value](#55-authoritative-value).

*See also:* [Lens-as-Data](#29-lens-as-data).

*References:*
- [W3C Verifiable Credentials Data Model](https://www.w3.org/TR/vc-data-model/).

---

### 5.5 Authoritative Value
A computed score for a piece of data based on the number, identity, and reputation of its [Signed States](#54-signed-state) (and possibly the trust graph among signers). Used in open historical databases to surface plausible vs. contested entries. Concrete formula is application-defined.

---

## 6. Architecture & Deployment

### 6.1 Local-First
The architectural stance, articulated by Ink & Switch, that user data lives primarily on user devices and remains available, editable, and useful without a central server. Graviola is local-first by default; servers, when present, are transports or accelerators, not authorities.

*References:*
- Kleppmann, Wiggins, van Hardenberg, McGranaghan, [*"Local-first software: You own your data, in spite of the cloud"*](https://www.inkandswitch.com/local-first/) (Ink & Switch, 2019).

---

### 6.2 Browser/Server Symmetry
The Graviola constraint that core layers (lens engine, validator, IVM) run identically in browser and server environments. Drives the choice of pure JS / WASM implementations and forbids server-only dependencies in core packages.

---

### 6.3 Classical Migration
The traditional path of evolving a schema by writing imperative migration scripts run in staging and production, typically against a relational or document database via an ORM. Graviola supports this path explicitly: where an application has strong authorship over its data model and runs a centralized backend (e.g., [Prisma](https://www.prisma.io/) on PostgreSQL or MongoDB), the [Lens](#25-lens) machinery is unnecessary and the application uses Prisma migrations directly. The lens engine is plugged into a concrete [AbstractDatastore](#66-abstractdatastore) implementation only when [Schema Drift](#24-schema-drift) across uncoordinated peers is actually a concern.

This dual path is deliberate. Lenses solve a real but specific problem (federated, uncoordinated, version-skewed peers); classical migration solves the common case (one team owns the database). Graviola treats both as first-class.

---

### 6.4 Spine vs. Tissue Packages
A monorepo discipline distinguishing **spine** packages (interfaces, contracts, types — versioned slowly, broadly depended on) from **tissue** packages (implementations — versioned freely, narrowly depended on). Reduces the sync burden of a 100-package monorepo.

*Example:* `@graviola/mapping-contracts` (spine) defines the `DeclarativeMapping` types; `@graviola/mapping-strategies-cultural-heritage` (tissue) implements specific strategies for that domain.

---

### 6.5 JSON Forms
The schema-driven form rendering library Graviola uses for UI generation. Embodies [Structural Dispatch](#12-structural-dispatch): a renderer registry resolves shape→component at runtime, decoupling UI from concrete entity types.

*References:*
- [JSON Forms](https://jsonforms.io/) (EclipseSource).

---

### 6.6 AbstractDatastore
Graviola's interface contract for a concrete data backend. Implementations include in-memory stores, Yjs-backed stores, SPARQL endpoints, Prisma-backed relational stores, and others. The lens engine, IVM layer, and signing layer are *opt-in* features that a given `AbstractDatastore` implementation may or may not expose; consumers of an `AbstractDatastore` discover available capabilities through its declared interface.

*See also:* [Capability Context](#47-capability-context), [Classical Migration](#63-classical-migration).

---

## Appendix: Reading Order for Newcomers

For a developer new to Graviola who wants to understand the conceptual stack, roughly in this order:

1. [Local-first software](https://www.inkandswitch.com/local-first/) (Kleppmann et al., 2019) — the why.
2. [Project Cambria](https://www.inkandswitch.com/cambria/) — the closest existing system.
3. Foster et al., [*Combinators for Bidirectional Tree Transformations*](https://www.cis.upenn.edu/~bcpierce/papers/lenses-toplas-final.pdf) — the lens foundations.
4. Lenzerini, [*Data Integration: A Theoretical Perspective*](https://dl.acm.org/doi/10.1145/543613.543644) — the federation framing.
5. Existing Graviola [Declarative Mapping](#31-declarative-mapping) code and example mappings (Wikidata person, GND).
6. [JSON Forms](https://jsonforms.io/) documentation — for the UI dispatch pattern that mirrors the data layer.
