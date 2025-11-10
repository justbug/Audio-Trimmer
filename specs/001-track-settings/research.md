# Research: Track Settings Entry Page

## Decision 1: Use TCA NavigationStackStore for handoff to AudioTrimmer
- Decision: Navigate from `TrackSettings` to `AudioTrimmer` using TCA’s `NavigationStackStore` (or a parent `AppRootFeature` that scopes into both features) and pass a `TrackConfiguration` through state when confirming.
- Rationale: Keeps navigation deterministic and testable, composes features without shared mutable state, and clearly defines the handoff contract via state rather than ad-hoc singletons.
- Alternatives considered:
  - Presenting `AudioTrimmerView` modally from SwiftUI without reducer composition: rejected due to weaker testability and unclear data flow.
  - Injecting configuration via global environment: rejected due to tight coupling and poor isolation in tests.

## Decision 2: Reducer-owned validation with string-based inputs
- Decision: Keep form fields as `String` in `TrackSettingsFeature.State` for SwiftUI bindings; parse and validate in reducer on `Confirm`. Maintain a per-field error dictionary and disable Confirm when invalid.
- Rationale: Avoids parsing side effects in SwiftUI, centralizes validation rules, keeps SwiftUI bindings simple, fully testable via `TestStore`.
- Alternatives considered:
  - Storing parsed numeric values in state and validating on-change: increases complexity and risks inconsistent dual sources of truth.
  - Validation in the view: violates separation of concerns and hinders testability.

## Decision 3: Key time normalization (clamp → round(2) → sort → unique)
- Decision: On submission, clamp each entered percentage to 0–100, round to 2 decimals for display, sort ascending, and de-duplicate exact duplicates post-rounding.
- Rationale: Matches spec requirements, ensures predictable UI and downstream rendering in the trimming view.
- Alternatives considered:
  - Allow more precision: unnecessary for UX; increased noise.
  - Disallow 0 or 100: spec allows boundaries; rejecting them adds confusion.

## Decision 4: Clip duration computed from percent; round only for display
- Decision: Compute `clipDuration = totalDuration * (clipPercent / 100)`. Internal value stays precise; UI shows up to 2 decimals. Validate `clipStart + clipDuration ≤ totalDuration`.
- Rationale: Prevents rounding artifacts, aligns display with spec guidance, avoids off-by-one visual glitches.
- Alternatives considered:
  - Rounding internally: can accumulate error and violate constraints on edge values.

## Decision 5: Deterministic tests with TestStore
- Decision: Use `TestStore` to assert validation errors, successful configuration mapping, and navigation effect. Inject `ImmediateClock` only if we add debounced field validation (not planned initially).
- Rationale: Mirrors current test strategy in repository; ensures stability as UI evolves.
- Alternatives considered:
  - UI snapshot tests for validation: heavier and slower; reducer tests already cover logic thoroughly.


