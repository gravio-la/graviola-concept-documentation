# Architecture and data flow

The framework is organized into six layers, each consuming only from layers below it:

```mermaid
graph TD
    L6["Layer 6 — UI Components<br/>SemanticTable, EntityFinder, advanced components"]
    L5["Layer 5 — Form Rendering<br/>SemanticJsonForm, GenericForm, JSON Forms renderers"]
    L4["Layer 4 — Store Providers<br/>SPARQL, Oxigraph, REST, Prisma, in-memory"]
    L3["Layer 3 — State Management<br/>React hooks, data mapping hooks"]
    L2["Layer 2 — Schema → Query Translation<br/>sparql-schema, graph-traversal, db-impl packages"]
    L1["Layer 1 — Foundation<br/>Core types, utils, JSON Schema utilities, JSON-LD utilities"]

    L6 --> L5
    L5 --> L4
    L5 --> L3
    L4 --> L3
    L3 --> L2
    L2 --> L1
```

Layers 1 and 2 are the **server-safe core**: no frontend dependencies, consumed by both browser applications and command-line tooling. Layers 3 and 4 introduce React and storage-specific code. Layers 5 and 6 are the user-facing surfaces.

The data flow for a typical read operation:

```mermaid
flowchart LR
    A["JSON Schema<br/>definition"] --> B["sparql-schema<br/>translator"]
    B --> C["SPARQL CONSTRUCT<br/>query"]
    C --> D["RDF graph<br/>from store"]
    D --> E["graph-traversal<br/>extractor"]
    E --> F["Typed JSON<br/>object"]
    F --> G["State hooks<br/>TanStack Query"]
    G --> H["React<br/>component"]
```

Writes follow the inverse pipeline: form data is validated against the schema, transformed into RDF triples (or the equivalent for non-RDF stores), and committed via INSERT/DELETE operations.

---

## See also

- [Capabilities today](capabilities-today.md) — what each layer provides in product terms.
- [Deployment scenarios](deployment-scenarios.md) — which layers matter in which deployments.
- [Glossary](glossary.md) — [Browser/server symmetry](glossary.md#62-browserserver-symmetry), [AbstractDatastore](glossary.md#66-abstractdatastore).
