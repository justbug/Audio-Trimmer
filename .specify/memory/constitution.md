<!--
Sync Impact Report
Version: N/A → 1.0.0
Modified Principles: (new) → Composable Architecture Discipline; (new) → Test-Driven Reliability; (new) → Consistent & Accessible UX; (new) → Performance & Efficiency Guarantees; (new) → Code Quality & Review Integrity
Added Sections: Engineering Constraints & Standards; Development Workflow & Quality Gates
Removed Sections: None
Templates Requiring Updates: ✅ .specify/templates/plan-template.md; ✅ .specify/templates/spec-template.md; ✅ .specify/templates/tasks-template.md
Follow-up TODOs: None
-->

# Audio Trimmer Constitution

## Core Principles

### Composable Architecture Discipline
All feature work MUST be implemented as Swift Composable Architecture (TCA) 1.23.0 reducers located under `App/Sources/App/Features/<FeatureName>/`. Each reducer defines `@ObservableState`, `Action`, and `Body`, scopes child features through `Scope`, and exposes dependencies via `DependencyValues`. SwiftUI views MAY only observe data through `StoreOf<Feature>` bindings and never mutate state directly. Cross-feature reuse happens through public reducer modules—shared mutable state or singleton-style managers are prohibited. Dependency clients MUST be testable, cancellable where effects recur, and resilient to failures.

### Test-Driven Reliability
Every reducer, dependency client, and view-driving logic MUST start with failing tests before implementation. Use TCA`s `TestStore`, the Swift `Testing` package, and deterministic schedulers to assert state evolution, action emissions, and effect lifecycles. No code may merge without automated unit coverage for reducers and snapshot or integration coverage for user-facing flows. Regression tests MUST accompany any bug fix. Long-running effects require cancellation coverage, and dependency overrides MUST document their expected behaviors.

### Consistent & Accessible UX
SwiftUI views MUST reflect a unified design language: shared components live under `App/Sources/App/SharedUI/`, and modifiers express styling rather than nested containers. All flows MUST expose VoiceOver labels, Dynamic Type scaling, high-contrast readiness, and haptic/auditory feedback parity. Navigation structures use `NavigationStackStore`, `IfLetStore`, or `SwitchStore` to keep state-driven routing predictable. UI changes MUST include preview snapshots or simulator captures to demonstrate compliance on iPhone and iPad form factors.

### Performance & Efficiency Guarantees
User interactions MUST respond within 100 ms, and scrolling/composition MUST sustain 60 fps on baseline iPhone hardware. Audio processing and waveform rendering MUST execute off the main thread using structured concurrency or dependency clients. Effects that touch disk or network MUST be profiled and instrumented with metrics exposed via dependencies. Performance budgets MUST be validated with benchmarks or instrumentation when reducers introduce new long-running work, and optimization tasks MUST be planned before features ship if targets cannot be met.

### Code Quality & Review Integrity
Code MUST stay idiomatic Swift 5.9+, leverage four-space indentation, avoid line lengths beyond ~120 characters, and document complex flows with succinct comments. Pull requests MUST describe architecture impacts, testing evidence, and user-facing implications. `swift format` (or Xcode default formatting) MUST run before review. Linting, static analysis, and dependency audits MUST block merges when violations occur. Feature reducers and clients MUST be annotated `public` only when cross-module sharing is required, and dead code MUST be removed promptly.

## Engineering Constraints & Standards

- Maintain a clear boundary between the Swift package (`App/`) and the Xcode wrapper (`Audio Trimmer/`); reusable logic lives in the package, while platform assets stay in the app target.
- Feature reducers MUST expose capability via dependency clients instead of referencing global singletons or UIKit APIs.
- Long-running tasks MUST use `Effect.run` with explicit cancellation identifiers and test coverage for cancellation scenarios.
- Persisted data, caches, and waveform assets MUST be accessed through dependency-injected clients that can be mocked in Tests.

## Development Workflow & Quality Gates

1. Every initiative MUST begin with a plan that passes the Constitution Check: architecture diagram scoped to reducers/stores, testing approach, UX preview strategy, and performance budget.
2. Implementation MUST follow the red-green-refactor loop: author failing tests, implement the reducer/view, refactor with tests passing.
3. All pull requests MUST include: summary, TCA reducer list, dependencies touched, screenshots or previews for UX, benchmarks when performance changes, and the exact commands run (`swift test --package-path App`, additional benchmarks).
4. Code review MUST confirm adherence to all principles; reviewers MUST block merges when tests, accessibility, performance, or architectural constraints are not satisfied.

## Governance

- This constitution supersedes informal practices. Amendments require consensus from maintainers and MUST document rationale, version bump type, and migration expectations.
- Versioning follows semantic rules: MAJOR for principle removals/conflicting changes, MINOR for new principles or sections, PATCH for clarifications.
- Compliance reviews occur at each release candidate milestone; failures halt release until remediation plans exist.
- Store this document in version control; reference it within onboarding materials and pull request templates to keep enforcement visible.

**Version**: 1.0.0 | **Ratified**: 2025-11-05 | **Last Amended**: 2025-11-05
