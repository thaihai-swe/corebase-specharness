# Code-Design Principles

> Ownership: `Kit-managed`

Same priority as `AGENTS.md` Section 0.

## Read before you write

- Inspect similar code before adding files; match local structure and style.
- Choose the smallest design that satisfies approved requirements.
- Keep fetching, domain logic, and presentation separated when they change independently.
- Use interfaces only for real boundaries or multiple implementations.
- No speculative wrappers, ports, injection slots, or deep inheritance.
- Preserve invariants behind validated APIs; never expose mutable internal state.
- Compose behavior rather than inherit it.

## One Contract and One Resolution Path

- One spelling and representation per intent.
- One canonical entry point for resolution, loading, and state changes.
- Move repeated caller setup into a shared helper.
- Centralize variant dispatch in one registry/resolver; avoid duplicated switches.
- Keep shared interfaces and implementations aligned; hide concrete-only behavior.

## Failures must reach a decision-maker

- Surface errors to a decision-maker; never return silent empty results.
- Distinguish no result, unavailable dependency, and skipped work.
- Make required setup internal or fail explicitly when absent.
- Validate schemas, docs, config, examples, and code together on behavior changes.

## Abstraction Check & Deep Modules

- Deletion test: keep a module only if deleting it duplicates complexity across callers; collapse it if deletion only concentrates work in one caller.
- Deep modules: maximize behavior behind small, simple public interfaces. Avoid shallow pass-through wrappers.
- Interface is the test surface: callers and tests cross the same seam. Do not invent internal mock seams when the public interface is testable.
- Require two distinct adapters before a permanent seam abstraction. One adapter is a hypothetical seam.

## Clean Architecture & Layering

- **Dependency Direction:** Source dependencies point inward toward core domain logic. Entities do not import persistence, HTTP frameworks, or UI libs.
- **Separation of Concerns:** Isolate business rules from persistence and transport. DB handles or HTTP objects do not pass into pure domain entities.
- **Ports & Adapters:** When domain needs external capabilities, declare ports in domain; outer layers implement adapters.
- **No Anemic Models:** Domain entities own their invariants, state transitions, and validation rules rather than acting as bare data holders.

## Domain-Driven Design (DDD)

- **Ubiquitous Language:** Code identifiers match `corebase-specharness/project/glossary.md` and domain packs. Do not substitute generic technical synonyms for business terms.
- **Aggregate Roots:** Group coupled entities under a root entity. External callers modify child state through methods on the root.
- **Value Objects:** Use immutable value objects for validated concepts (amounts, emails, ranges) instead of primitive types.
- **Bounded Contexts:** Do not force a monolithic entity across divergent domains. Use separate models with explicit boundary mappings.

## Verify the path you claim to have fixed

- Run an end-to-end command exercising the changed path and verify side effects.
- Search for equivalent shapes when fixing a repeated defect class.
- Do not claim success from compilation, mocks, or type checks alone when the real path is testable.
