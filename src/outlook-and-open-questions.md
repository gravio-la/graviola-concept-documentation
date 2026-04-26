# Outlook and open questions

This chapter collects **unresolved design tensions** and research-style questions that arise from combining Graviola's trajectory (lenses, calculated fields, signing, federated sync) with real deployments. It is intentionally separate from the [Glossary](glossary.md), which stays focused on **definitions** and stable vocabulary.

For capabilities that are directionally chosen but not yet production guarantees, see [Architectural trajectory](trajectory.md). For how generative tooling may attach to schema-driven workflows without changing the framework's core contract, see [Graviola in the age of generative tools](graviola-in-the-age-of-generative-tools.md).

---

## Cross-version calc sync

How to reconcile a [Calculated field](glossary.md#41-calculated-field) computed on a peer at `V_a` with one computed on a peer at `V_b` when the underlying schemas are linked by a [Lossy lens](glossary.md#213-lossy-lens). Likely requires the calc to declare its valid version range and the runtime to skip cross-version cache reuse.

---

## Lens inference

Whether (and to what extent) lenses between adjacent schema versions can be inferred from a structural diff of the schemas themselves, rather than authored by hand. Promising for trivial cases (rename, add-with-default); intractable in general.

---

## Provenance through lenses

How [Signed state](glossary.md#54-signed-state) survives forward-and-back migration. A signature over `Person_V1` is not a signature over `Person_V2` — but if the lens is signed and well-behaved, the trust can be transitively reconstructed. Design unclear.

---

## Calc migration across lossy boundaries

When a [Calculated field](glossary.md#41-calculated-field) reads a field that gets split or merged by a [Lossy lens](glossary.md#213-lossy-lens), the formula no longer references valid sources in the new schema. Auto-rewriting formulas across lossy boundaries silently produces wrong results; the safe default is to mark the calc as invalidated under that migration and surface it. A better answer is open.

---

## See also

- [Architectural trajectory](trajectory.md) — where each frontier topic connects to intended architecture.
- [Glossary](glossary.md) — formal definitions and references for terms used above.
