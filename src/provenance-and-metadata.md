# Provenance and metadata

Graviola distinguishes **two granularities of metadata**: fact-level (statement-level) and entity-level (record-level / administrative). The framework intends to guarantee entity-level metadata on every backend while negotiating fact-level provenance through store capabilities.

Everything in this chapter is **proposed**, not yet implemented in production unless noted. Pipeline-level provenance in the `ReadResult` envelope exists today for progressive materialization; fact-level statement metadata and MetaSchema are trajectory.

Related: [The sidecar pattern](sidecar-pattern.md), [Calculated fields](calculated-fields.md), [Store topology](store-topology.md).

---

## Two granularities, two names

| Granularity | Name | Examples |
|---|---|---|
| **Fact level** | Statement-level metadata | Source, rank, generated-at, qualifiers on a single asserted value |
| **Entity level** | Administrative / record-level metadata | Created, modified, schema version, custodial history of the *record* |

Conflating administrative and descriptive metadata is a classic modeling failure mode. Entity metadata describes the record as a unit; fact metadata describes individual assertions within it.

Literature anchor for fact granularity: Ding et al., *Tracking RDF Graph Provenance using RDF Molecules* (2005) — graph/document, molecule, triple granularity.

---

## The named-entity boundary is a CBD

Graviola's **named entity** — a document that can be deep but stops wherever something links to another *named* thing — is precisely the **Concise Bounded Description (CBD)** extraction rule: descend into anonymous/subordinate structure; halt at named IRIs.

The extract-graph pipeline has implicitly used this boundary; naming it makes entity-level metadata rigorous:

> **Entity metadata is metadata whose subject is the CBD as a unit, not any triple within it.**

(DDD analogy: Aggregate + root.)

### Write granularity rule

> **Invariant:** *The granularity of the write determines the granularity of the metadata.* Replacing a CBD (saving an entity) stamps entity-level `modified`; a sub-CBD mutation (setting certain fields) produces statement-level metadata.

---

## Fact-level provenance: the Wikidata statement-node pattern

### Canonical logical model

Direct ("truthy") property alongside a statement node reached by a one-hop-longer property (`p:` → statement → `ps:` value + qualifiers + references; `wdt:` as truthy shortcut).

Chosen as canonical **because it is expressible in plain SPARQL 1.1 triples** — everything else is a storage *encoding* of it. Consistent with capability-declaring philosophy: the abstract model is universal; the encoding is negotiated.

### Capability extension

New capability facet on the [Store](glossary.md#621-store) descriptor (naming to align with `@graviola/store-core` conventions):

```typescript
provenance?: {
  statementLevel: 'rdf-star' | 'statement-node' | 'named-graph' | 'side-table' | 'none';
  entityLevel: boolean;
}
```

Typical assignments: Oxigraph → `rdf-star`; generic SPARQL 1.1 → `statement-node`; quad stores → `named-graph`; Prisma → generated `_statements` side table; REST → `none`.

**`none` still isn't zero provenance:** pipeline-level provenance (which store answered, when materialized, query fingerprint) is **framework-guaranteed** — it exists as `ReadResult.provenance` and progressive-materialization triples (`prov:wasAttributedTo`, `prov:generatedAtTime`). Only *fact-level* provenance is capability-gated; where a store cannot carry statement annotations natively, the materialization layer carries them (declared, not hidden — same honesty discipline as capability simulators).

### Schema derivation: `$stmt`

`deriveProvenanceSchema(schema)` — pure Layer-1 function. For each property, emits the original (truthy) plus a `$stmt` sibling array:

`{ value, rank: preferred|normal|deprecated, source, generatedAt, wasGeneratedBy, qualifiers }`

Because the derived artifact is ordinary JSON Schema, existing machinery works unchanged: sparql-schema emits the one-hop-longer CONSTRUCT (per SPARQL flavour), graph-traversal extracts it, DetailRenderer can render a provenance panel, typed filters can constrain on it:

```typescript
where: { birthDate$stmt: { some: { source: 'nas01', rank: 'preferred' } } }
```

### Write policy — do not reify everything

Statement nodes multiply triple count 3–5×. Per-property declarative policy: `provenance: always | on-conflict | never` (LinkML annotation → sidecar/derived artifact).

**`on-conflict`** is the federation-relevant mode: the direct triple exists alone until a *second* source asserts a different value; then both values get statement nodes with source provenance and the truthy triple becomes a **resolved** value. Resolution = rank + source trust weight — computing the truthy triple is itself a Stratum-1-style derivation, connecting provenance to the [weights pass](calculated-fields.md#two-passes-structure-then-weights).

> **Invariant:** Truthy property and statement array are **dual-asserted on write** (as Wikidata does). Never derive truthy at query time — otherwise every read pays resolution cost and completeness guarantees get murky.

---

## Entity-level metadata: `$meta`

### Asymmetric guarantees

- **Entity-level metadata is framework-guaranteed, never capability-gated.** It degrades to plain triples (or columns) on any backend including REST and Prisma. Preferred encoding where quads exist: **named graph per entity** (graph-per-aggregate; the graph node carries `dct:created`, `dct:modified`, `gra:schemaVersion`, `prov:wasAttributedTo`).
- **Fact-level metadata is the negotiated capability** (above).

Every store can say when a *document* changed; only some can say when a *field* changed.

### `$meta` derivation

One `$meta` block per **named entity** in derived schemas — nested *named* entities in a deep result each carry their own `$meta`; anonymous nested structure never does. The CBD boundary decides mechanically; no per-schema annotation.

Interlock, not duplication: entity `modified` is derivable as `max(generatedAt)` over statement metadata where fact-level exists, stored directly where it doesn't (same dual-assertion discipline as the truthy triple). `gra:schemaVersion` at entity level is the anchor the future lens/migration system needs ([Entity version](glossary.md#22-entity-version)).

> **Invariant:** `$meta` is **system-asserted, never user-asserted**. It is excluded from the write-validation schema; client-supplied `$meta` on upsert is rejected or ignored. Otherwise administrative metadata silently becomes descriptive data with a funny name.

Reads opt in via `include: { $meta: true }` (mirroring the typed filter surface). SemanticTable meta columns, DetailRenderer provenance panels, and typed filters over `$meta` require **zero new rendering or query machinery** — the composed artifact is ordinary JSON Schema.

---

## The MetaSchema sidecar

Application-extensible document-level metadata **must not live in the domain schema**. It is the third [sidecar](sidecar-pattern.md) instance: **data schema / UI schema / meta schema**.

- A MetaSchema is an ordinary JSON Schema document with its own `$id`, registered alongside domain schemas (`metaSchemata: { default, byType }` in provider config, resolved with the same discipline as extended schemas).
- The framework ships a **base profile** (created / modified / schemaVersion / provenance — the framework-guaranteed floor) with dct:/prov: vocabulary mappings; applications extend via `allOf` (e.g. `reviewStatus`, `importBatch`, `catalogingAgency`, `syncState`).
- **Extension fields require IRI mappings** like domain fields so entity-level and fact-level metadata land in the same RDF graph with real semantics — never a JSON-blob property.
- **MetaSchema is schema-as-data**: storable in the triple store, versioned, referenced from entity metadata (`gra:metaSchemaVersion` alongside `gra:schemaVersion`) so administrative metadata is migratable with the same future lens machinery as domain data.
- Composition: `deriveExtendedSchema(domainSchema, metaSchema)` grafts typed `$meta` onto each CBD boundary. The **write-validation path consumes the domain artifact only**.

---

## Stratification and provenance

Computed triples carry `prov:wasGeneratedBy` → `{formulaId, stratum, inputFingerprint}`. Invalidation is provenance-driven — see [Calculated fields — Provenance tie-in](calculated-fields.md#provenance-tie-in).

---

## See also

- [Calculated fields](calculated-fields.md) — materialized computed values and invalidation.
- [Store topology](store-topology.md) — CBD-cut invariant and composite stores.
- [Architectural trajectory](trajectory.md) — signed states and authoritative value.
- [Outlook and open questions](outlook-and-open-questions.md) — provenance through lenses.
- [Glossary](glossary.md) — [Statement-level metadata](glossary.md#56-statement-level-metadata), [MetaSchema](glossary.md#620-metaschema).
