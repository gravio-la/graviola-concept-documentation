# Lenses and bidirectional transforms

Graviola's trajectory treats **lenses** — bidirectional transformations with `get`/`put` pairs and round-trip laws — as a unifying concept spanning several surfaces that today look unrelated: inverse properties, writable computed fields, declarative mappings with a reverse direction, and version migrations (Cambria-shaped).

This chapter is **proposed** concept material. Version lenses are trajectory; `x-inverseOf` exists in production JSON Schema today but is on a retirement path toward the general lens mechanism.

For foundational lens vocabulary, see [Glossary — Lens](glossary.md#25-lens). For calculated fields, see [Calculated fields](calculated-fields.md).

---

## One concept, four surfaces

| Surface | Direction today | Lens framing |
|---|---|---|
| **`x-inverseOf`** | Bidirectional relationship writes | Self-inverse, total, lossless lens — the trivial case |
| **Writable computed** | `get` only (read-only derived fields) | Lens with explicit `put` block in calc sidecar |
| **Declarative mapping** | Forward-only (authority → local) | Lens between external and local schema when reverse is authored |
| **Version migration** | Cambria / trajectory | Lens between schema versions |

The insight for the concept book: **`x-inverseOf` is a special case hardcoded where a general concept belongs.** It can become a compiler-recognized bidirectional slot pattern — self-inverse lens (`put` = assert mirrored triple, `delete` = retract) — while user-visible behavior (set the relationship from either side) survives as the simplest instance of the general mechanism.

---

## Round-trip laws

Well-behaved lenses satisfy the canonical [lens laws](glossary.md#28-lens-law):

- **GetPut:** `put(get(s)) = s`
- **PutGet:** `get(put(s, v)) = v`
- **PutPut:** putting twice equals putting once with the latest value (very well-behaved lenses)

The compiler *checks* round-trip laws where possible (property-testing with generated instances in dev mode). The author writes the reverse direction explicitly; **formulas are never inverted symbolically** (computer algebra is a tarpit).

---

## Invertibility spectrum

1. **Bijective** — unit conversions, `inverseOf`. Both directions total and exact.
2. **Injective, partial** — invertible where defined; out-of-range write fails validation.
3. **Lossy get, recoverable put** — classic lens: `fullName` loses the split point; `put` recovers it *from current source state* — hence `put(source, newValue)`, never `inverse(newValue)`.
4. **Non-invertible** — `SUM(...)`. No canonical put. An application *may* author a distribution policy (pro-rata etc.), but that is domain logic, explicitly authored, never a default.

---

## Writable computed fields

Mechanics (proposed):

- A calc profile slot entry gains an optional `put` block (bindings + assignment expressions).
- No `put` → derived schema keeps `readOnly: true`.
- `put` present → derived schema drops `readOnly`; forms render the field editable; a write compiles into writes to binding targets.
- **Writability of the derived schema is computed from the sidecar** — not declared by the domain author.
- **Puts may only target Stratum 0 slots** (stored values) in v1. Chained inversion (put targeting another computed) is composable in theory but forbidden until a real use case argues it in.
- Put effects re-enter the dependency graph at their targets' strata; existing cycle detection covers pathological get/put loops.

See [Calculated fields](calculated-fields.md) for stratification and the calc profile sidecar.

---

## Retirement path for `x-inverseOf`

On its own refactoring schedule, the JSON Schema extension can be removed while behavior is preserved via the self-inverse lens pattern. The same track leads to mappings-with-reverse and version lenses (Cambria, natively) as instances of one abstraction.

---

## Open question: cross-CBD puts

v1 instinct: restrict put targets to bindings within the same [named entity (CBD)](glossary.md#619-concise-bounded-description-cbd), because cross-entity puts reopen authorization, provenance attribution, and transactionality simultaneously.

But inverse-property users *already* perform cross-entity writes (adding a child writes the parent's collection). The restriction may not survive real usage. This is recorded as open in [Outlook and open questions](outlook-and-open-questions.md#cross-cbd-puts).

---

## See also

- [Architectural trajectory](trajectory.md) — schema evolution via lenses.
- [The sidecar pattern](sidecar-pattern.md) — calc profile carries `put` blocks.
- [Provenance and metadata](provenance-and-metadata.md) — granularity of writes and metadata.
- [Glossary](glossary.md) — [Asymmetric lens](glossary.md#26-asymmetric-lens), [Lossy lens](glossary.md#213-lossy-lens), [Put](glossary.md#413-put-graviola-sense).
