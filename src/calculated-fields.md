# Calculated fields

Some schema properties are best expressed as derivations rather than stored values: a person's full name from forename and surname; an aggregate across linked entities; a status flag from temporal conditions. Graviola's intended mechanism is a **declarative formula language** (HyperFormula-shaped), with dependencies, stratification, and capability-aware evaluation placement.

Everything in this chapter is **proposed or designed but not implemented** in production unless explicitly marked. For what ships today, see [Capabilities today](capabilities-today.md).

Related: [The sidecar pattern](sidecar-pattern.md), [Lenses and bidirectional transforms](lenses-and-bidirectional-transforms.md), [Provenance and metadata](provenance-and-metadata.md), [Store topology](store-topology.md).

---

## Three artifact forms, one concern

| Form | Audience | Expansion policy |
|---|---|---|
| **LinkML annotations** (`graviola.computed`) | Schema author | Maximally terse; [defaults ladder](#the-defaults-ladder) |
| **Calc profile sidecar** (JSON, scope-keyed) | Generated artifact, reviewed/diffed | Terse — omitted defaults stay omitted; regenerated, diffable |
| **Compiled profile** | Runtime + debugging | Fully expanded **plus derived facts**: cardinality per binding, assigned stratum, resolved eval placement, reverse `dependents` adjacency |

Debuggability lives in the **compiled** form, where expansion is deterministic and derived — never in the authored forms, where expanded defaults would masquerade as intent. A CLI affordance (`graviola calc explain '<scope>'`) is intended to print the expanded slot with its strata chain.

The LinkML generator emits **two build artifacts**: (a) a clean domain JSON Schema in which computed slots are ordinary `readOnly: true` properties; (b) the [calc profile sidecar](sidecar-pattern.md). Mapping is mechanical, one-to-one.

---

## The defaults ladder

The authoring surface escalates only when convention is insufficient.

**Level 0** — bare formula string; bare variable names auto-bind to same-named sibling slots; implied `eval: auto`, `cache: reactive`, `readOnly: true`:

```yaml
full_name:
  range: string
  annotations:
    graviola.computed: 'CONCAT(forename, " ", surname)'
```

**Level 1** — dotted names in formulas are [binding paths](glossary.md#16-binding-path) (ABox traversal, compile-time validated):

```yaml
graviola.computed: 'CONCAT(owner.display_name, " — ", TEXT(area_sqm))'
```

**Level 2** — structured annotation when convention is insufficient (renamed bindings, context roots, explicit `eval`):

```yaml
graviola.computed:
  bindings:
    owner_id: { path: owner.id }
    me: { context: currentUser.id }
  formula: 'EQ(owner_id, me)'
  eval: client
```

**Level 3** — aggregates over relationships; LinkML `multivalued:` and `inverse:` supply relationship facts (cardinality derived, never declared):

```yaml
billable_area_total:
  annotations:
    graviola.computed:
      aggregate: { type: sum, over: plots, field: billable_area }
```

Chained computeds across parent–child (Plot.billable_area → Patch.billable_area_total → Garden.total_billable → Garden.annual_fee) stratify automatically: stratum = `max(dependencies) + 1`.

**Deliberate v1 omission:** no `where:` filter inside `aggregate`. The idiomatic pattern is *define an intrinsic computed, then aggregate it* — intermediates stay individually inspectable, renderable, provenance-carrying, and stratify more cleanly. Relation-query bindings (`relation` + Prisma-style `where`) are the level-4 escape before a resolver hatch.

The `graviola.computed` annotation schema itself is intended to ship as a LinkML model (`graviola-annotations.yaml`) so authors get editor validation.

---

## Calc profile sidecar

Example shape:

```json
{
  "$schema": "https://graviola.top/calc-profile/v1",
  "appliesTo": { "schema": "https://myapp/schema", "fingerprint": "sha256-…" },
  "slots": {
    "#/definitions/Person/properties/fullName": {
      "formula": "CONCAT(forename, \" \", surname)"
    }
  }
}
```

See [The sidecar pattern](sidecar-pattern.md) for fingerprint binding and scope/path duality.

---

## Compilation, dependency graph, and stratification

### Formula × auth stratification `[DESIGNED]`

```
Stratum 0  →  ground data (stored values)
Stratum 1  →  intrinsic formulas (S0 + S1 dependencies only)
               ↑ auth rules MAY reference up to here
────────────── AUTH BOUNDARY ──────────────
Stratum 2+ →  contextual formulas (operate over auth-scoped / boundary-scoped data slices)
```

An auth rule referencing a Stratum-2+ slot is a **hard compiler error** with the dependency chain and a concrete fix named in the message. Cycles are errors, never fixpoints — grouped topological sort + cycle detection (O(V+E)); no Datalog engine.

The **boundary profile** is parameterized: auth rules on a server, and/or **completeness-scoped slots** on the client. In browser-only deployments the same mechanism enforces **correctness**, not security: "this aggregate ran over an incomplete set" is the client-side sibling of "this aggregate ran over an auth-scoped set."

### Graph operations strategy `[PROPOSED]`

- **Never analyze JSON Schema directly.** Pipeline: schema(s) → extract computed + policy declarations → **intermediate dependency graph (IR)** → analyze → emit compiled profile. Needed for `$ref` resolution, cross-type binding paths, virtual nodes (the AUTH BOUNDARY node), and stable `slotAddress` node IDs.
- **Library: graphology** at compile time (Layer-2-safe; runs in Bun and browser). Domain logic (boundary node insertion, stratum assignment, boundary check) remains self-owned.
- **Zero graph libraries at runtime.** The compiled profile is serialized JSON:

```typescript
type CompiledSlot = {
  stratum: number;
  dependents: SlotAddress[];   // reverse adjacency, precomputed
  sources: StoreId[];
  cost: CostHint;
};
// Map<SlotAddress, CompiledSlot> + schemaFingerprint
```

Recomputation after a write = collect transitive `dependents` of the dirty slot, order by precomputed stratum, evaluate. This is interim incremental view maintenance — sufficient until true delta computation is needed ([Outlook](outlook-and-open-questions.md#true-ivm-vs-reverse-dependents)).

### Compile/runtime split is temporal, not topological

> **Invariant:** "Compiler" ≠ "server". Compilation runs when a schema arrives or changes; runtime runs on every write. In local-first deployments the browser runs both.

Compilation must be a **pure function `(schemaSet) → compiledProfile`** with no environment assumptions. The compiled profile is persisted next to the data (for example IndexedDB alongside the hexastore), keyed by `schemaFingerprint`. Contract tests must run the compiler under Bun **and** in a browser context to enforce Layer-1/2 [browser/server symmetry](glossary.md#62-browserserver-symmetry).

### Two passes: structure, then weights

> **Invariant:** Pass 1 (structural stratification) is purely structural — **weights must never influence strata** (otherwise auth soundness becomes cost-dependent).

- **Pass 1 — structural:** stratification via grouped topological sort.
- **Pass 2 — cost/placement:** annotate binding nodes with candidate sources + cost class (static, compile time), then select per query (dynamic, runtime): a cheap argmin over candidates consulting live completeness metadata and source availability. Per-node lookup, not a graph algorithm. Local completeness `=== true` trumps everything ("zero network calls" property).

---

## Complexity and capability context

Each calculated field declares its computational cost class and the resources it requires. Graviola's deployment targets range from in-browser applications on commodity hardware to server-side processes with substantial compute. The runtime chooses between eager and lazy evaluation, or refuses to evaluate, based on the host's declared [capability context](glossary.md#47-capability-context).

---

## Provenance tie-in

A computed field materialized as a triple can carry `prov:wasGeneratedBy` → `{formulaId, stratum, inputFingerprint}`. Invalidation becomes provenance-driven: dirty input ⇒ every triple whose generating activity references it is stale — the same reverse-`dependents` walk from the compiled profile, persisted in the graph. See [Provenance and metadata](provenance-and-metadata.md).

---

## See also

- [Lenses and bidirectional transforms](lenses-and-bidirectional-transforms.md) — writable computeds and the `put` direction.
- [LinkML as an authoring source for schemas](linkml-authoring.md) — `graviola.computed` annotations in the build pipeline.
- [Architectural trajectory](trajectory.md) — trajectory overview.
- [Outlook and open questions](outlook-and-open-questions.md) — cross-version calc sync, true IVM, relation-query bindings.
- [Glossary](glossary.md) — [Calculated field](glossary.md#41-calculated-field), [Stratification](glossary.md#43-stratification), [Compiled profile](glossary.md#410-compiled-profile).
