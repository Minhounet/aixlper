# Proposal: extend the Java skills to Kotlin and Scala

> Status: **Deferred (2026-10-06).** The author doesn't use Kotlin or Scala
> yet. Nothing has changed in the skills. Pick this up only when one of
> those languages is actually needed.

## Current state

`igiari-tdd`, `chottomatte-archi` and `kanpeki-fp` all say "for Java" in
their `description`, so they won't trigger on `.kt` or `.scala` work. Most
of their principles are language-neutral. The mechanics are not.

| Skill | Carries over | Java-only today |
|---|---|---|
| `igiari-tdd` | One failing test at a time, minimal implementation, refactor checkpoint, test plan before the first cycle | Build commands cover Maven/Gradle but not sbt; code-style and preference sections use Java idioms (`java.util.Optional`, `null`) |
| `chottomatte-archi` | Dependency inversion via interfaces, constructor injection, use case as entry point, in-memory repository ports, Request/Response + mappers | Build-verification grep matches `\.java:[0-9]+` only; Scala ecosystems often wire with ZIO layers / tagless final instead |
| `kanpeki-fp` | Functional core / imperative shell, known failures in the signature, no `null`, loop → pipeline | The whole skill is Vavr, which backfills what Kotlin and Scala have natively. Kotlin prefers nullable `T?` over `Option` (Arrow agrees); Scala has `Option`/`Either`/sealed traits in its stdlib |

## Plan when needed

1. **`igiari-tdd` and `chottomatte-archi`: widen to the JVM.** Keep the
   rules in `SKILL.md`, add `references/kotlin.md` / `references/scala.md`
   (build commands incl. sbt `testOnly` / `~testOnly`, test frameworks,
   idioms), fix the `.java`-only grep, widen the `description`.
2. **`kanpeki-fp`: leave it Java/Vavr.** If FP guidance is needed for
   another language, write a sibling skill (Kotlin + Arrow, or Scala +
   stdlib/cats) rather than adding branches here.
3. **Eval before trusting it.** A widened `description` changes triggering,
   so add a case (see "When to add an eval case" in `CLAUDE.md`), and
   dogfood with a Kotlin kata the same way the Java skills were.
