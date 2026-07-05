# Store topology

Graviola's storage layer today is the **`Store`** interface in `@graviola/store-core`: capability facets composed by intersection, mirrored at runtime by the **`CapabilityDescriptor`**. Concrete backends implement subsets of those facets; the framework simulates missing capabilities honestly.

The **Store Registry** (federation across multiple stores) is **not yet implemented** in the form described here. This chapter records registry-level design vocabulary so deployment planning and new backends stay compatible.

For what ships today, see [Capabilities today](capabilities-today.md). The legacy term *AbstractDatastore* still appears in some packages; new concept material uses **Store** only.

Related: [Provenance and metadata](provenance-and-metadata.md), [Calculated fields](calculated-fields.md), [The shape of a federated application](federated-application.md).

---

## Store roles are dimensions, not categories

Deployment lists ("main DB", "cache", "helper DB", "translator") are folk taxonomy. The intended orthogonal dimensions:

| Dimension | Question | Notes |
|---|---|---|
| **Authority** | Source of truth, or derivable from one? | A *deployment role*, never an engine property — the same Oxigraph is authoritative in one deployment and a cache in another |
| **Durability** | Survives process/session/device loss? | in-memory Oxigraph vs IndexedDB vs server store |
| **Derivability** | Rebuildable from a named other store? | **New registry relation: `derivedFrom: storeId`** |
| **Shape fidelity** | Returns schema-shaped documents, or raw triples needing extract-graph? | **New capability flag.** Prisma/REST: shaped; SPARQL: raw. The graph-traversal last mile is skipped when the store declares shape fidelity |
| **Nativeness** | Real database vs translator over another application's state | Thunderbird, mount hierarchies — read-only registry stores; no new concept |

### `derivedFrom`

This relation pays three ways:

1. **Reindexing** is a defined operation (`rebuild(meilisearch)` = replay from its authority).
2. **Invalidation** has a direction (truth changed → derived stale).
3. **Federation "winning strategies"** get an objective ordering (authoritative beats derived at equal recency; then rank/trust weights — see [on-conflict reification](provenance-and-metadata.md#write-policy--do-not-reify-everything)).

---

## The composite store pattern

Two (or more) physical engines behind **one** `Store` — the internal seam invisible to the registry. One component holds authority; the other is a derived specialization.

Examples:

- QLever + writable endpoint (read speed + write path)
- Blazegraph + Meilisearch (full-text; Meilisearch always reindexable from Blazegraph)
- Oxigraph + PostGIS (geo)
- PostgreSQL + TimescaleDB (fast-accumulating properties)

The composite declares the **union** of its components' capabilities in its descriptor and routes internally.

**Why composites exist:** to hide a store boundary that would otherwise cut through an entity. Postgres+Timescale is the sharp case — an entity's fast-accumulating properties live in a different physical engine than its stable properties; the store boundary cuts *through the CBD*. Exposed to the registry: consistency nightmare. Encapsulated: the entity stays whole from outside.

---

## The CBD-cut invariant

> **The entity boundary (CBD) is the unit of consistency and metadata; the store boundary is the unit of availability, capability, and provenance. The store boundary must never visibly cut the entity boundary:** either an entity's CBD lives wholly within one registered store, or the cut is hidden inside a composite store that presents wholeness. Cross-store *links between* entities are normal federation; cross-store *splits within* an entity are the composite's job.

Existing design already assumes this quietly (entity `$meta` stamped per store, completeness per type+filter+source, put targets restricted to one CBD) — this promotes the assumption to a stated invariant.

See [Concise Bounded Description (CBD)](glossary.md#619-concise-bounded-description-cbd).

---

## React Query — position defended

TanStack Query stays in the UI layer. Its position is architecturally defensible: it caches **extract-graph outputs** keyed by query — denormalized render-shaped JSON, a different artifact from anything below (not triples, not entities).

What degrades as store complexity grows is only its *invalidation heuristic* (key-pattern matching). The eventual fix is **not** moving RQ down but feeding it signals from below: completeness metadata + the compiled profile's reverse-`dependents` already know which type+filter sets a write dirties → emit affected query fingerprints upward; RQ invalidates those keys. RQ demotes from *deciding* invalidation to *delivering* it. Incremental, no rework.

---

## The guardrail principle

> **Every store scenario must be expressible with existing vocabulary — role, capability facet/descriptor, `derivedFrom`, composite, shape fidelity. If a new deployment ever seems to require a new *mechanism*, that is the smell to investigate before building.**

Net-new registry vocabulary from the July 2026 design session is deliberately modest: one relation (`derivedFrom`), one wrapper pattern (composite store), one invariant (CBD-cut), one capability flag (shape fidelity). No new algorithms, no new artifact kinds.

---

## See also

- [Provenance and metadata](provenance-and-metadata.md) — entity vs fact metadata across stores.
- [Calculated fields](calculated-fields.md) — completeness metadata and source selection.
- [Deployment scenarios](deployment-scenarios.md) — where multi-store shapes appear in practice.
- [Architectural trajectory](trajectory.md) — federation overview.
- [Glossary](glossary.md) — [Composite store](glossary.md#625-composite-store), [Shape fidelity](glossary.md#626-shape-fidelity), [derivedFrom](glossary.md#624-derivedfrom).
