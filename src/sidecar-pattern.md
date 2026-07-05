# The sidecar pattern

Orthogonal concerns — rendering, computation, administrative metadata — must not pollute the domain schema. Graviola's intended model keeps the **domain JSON Schema pure** and carries each concern in a **scope-keyed sidecar**: a companion document whose keys are [Scopes](glossary.md#15-scope) (JSON Pointers into the schema document) and whose values are concern-specific payloads.

This pattern is **proposed**, not yet fully implemented across all three instances described below. It is documented here so current authoring and build pipelines can converge on one structural convention.

For **what ships today**, see [Capabilities today](capabilities-today.md). UI schema sidecars are in production use via JSON Forms; calc profiles and MetaSchema are trajectory material.

---

## Three sidecars, one dispatch rule

| Sidecar | Concern | Status |
|---|---|---|
| **UI schema** | Rendering hints for JSON Forms | Production (hand-authored or generated) |
| **Calc profile** | Computation declarations | Proposed — see [Calculated fields](calculated-fields.md) |
| **MetaSchema** | Entity-level administrative metadata | Proposed — see [Provenance and metadata](provenance-and-metadata.md) |

All three dispatch identically: a **TBox pointer (scope)** on the outside, a concern-specific payload on the inside. Consumers that care perform a scope lookup; consumers that do not remain ignorant.

This resolves the [Scope vs. binding path](glossary.md#15-scope) duality **structurally**: sidecar keys are always scopes (which schema slot does this apply to?); binding declarations *inside* sidecar entries are always [binding paths](glossary.md#16-binding-path) (what instance data feeds the concern?). The category error — using a scope where a path is needed, or vice versa — becomes impossible to express in the sidecar format.

---

## Fingerprint binding

Each sidecar declares which domain schema it applies to:

```json
{
  "appliesTo": {
    "schema": "https://myapp/schema",
    "fingerprint": "sha256-…"
  }
}
```

The fingerprint binds the sidecar to a concrete schema state. When the domain schema changes, drift detection is a **compile failure** naming the dangling scope — the same discipline applies to calc profiles, completeness metadata, and compiled computation artifacts. Sidecars are regenerated or updated in the build pipeline; they are not silently stale at runtime.

---

## Domain schema stays portable

Computed slots in the domain schema appear as ordinary `readOnly: true` properties — no `x-graviola-computed`, no computation vocabulary in the domain artifact. Whether a read-only field is **computed** or **stored-but-immutable** is determined only by **sidecar presence at that scope**, exactly as JSON Forms decides whether a control has custom UI schema.

Consequences:

- A consumer without the calc runtime sees a valid schema with read-only fields — graceful degradation.
- DetailRenderer can show a formula badge or an "explain this value" affordance by scope lookup without changing the domain schema.
- The [LinkML authoring](linkml-authoring.md) generator emits a clean domain JSON Schema plus separate sidecars mechanically, one-to-one.

---

## Composition at read time

Sidecars compose with the domain schema only where the extended structure is queried or rendered:

- `deriveExtendedSchema(domainSchema, metaSchema)` grafts typed `$meta` onto each [CBD](glossary.md#619-concise-bounded-description-cbd) boundary.
- `deriveProvenanceSchema(schema)` grafts `$stmt` siblings onto properties where fact-level provenance applies.

The **write-validation path consumes the domain artifact only**. The write validator does not know `$meta` or calc machinery exists — which enforces that administrative and computed metadata are system-asserted, not user-supplied.

---

## See also

- [Calculated fields](calculated-fields.md) — calc profile sidecar and compiled profile.
- [Provenance and metadata](provenance-and-metadata.md) — MetaSchema and `$stmt` derivation.
- [LinkML as an authoring source for schemas](linkml-authoring.md) — build-time emission of sidecars.
- [Architectural trajectory](trajectory.md) — overview of proposed capabilities.
- [Glossary](glossary.md) — [Calc profile](glossary.md#49-calc-profile-sidecar), [MetaSchema](glossary.md#620-metaschema).
