# Tasks: Track Settings Entry Page

## Dependencies & Order
- User Story order: US1 → US2 → US3
  - US1 (P1): Entry screen with validation and navigation to trimming
  - US2 (P1): Validation error rendering and confirm disabling
  - US3 (P2): Key times multiple input with normalization (clamp → round(2) → sort → unique)

Parallelization opportunities are marked with [P] where tasks touch independent files.

---

## Phase 1: Setup

- [X] T001 Create feature directory for TrackSettings under `Audio Trimmer/App/Sources/App/Features/TrackSettings/`
- [X] T002 Add empty tests file `Audio Trimmer/App/Tests/AppTests/TrackSettingsTests.swift`

## Phase 2: Foundational

- [X] T003 Define `TrackSettingsFeature` skeleton with `@Reducer` in `Audio Trimmer/App/Sources/App/Features/TrackSettings/TrackSettingsFeature.swift`
- [X] T004 Define `TrackSettingsView` skeleton bound to `StoreOf<TrackSettingsFeature>` in `Audio Trimmer/App/Sources/App/Features/TrackSettings/TrackSettingsView.swift`
- [X] T005 Update `Audio Trimmer/App/Sources/App/RootView.swift` to present `TrackSettingsView` as entry screen

---

## Phase 3: US1 – Configure and navigate to trimming (P1)
Goal: Users can input track length, clip start, clip percent, key times and, on Confirm, navigate to `AudioTrimmerView` with a correctly formed `TrackConfiguration`.
Independent test criteria: Given valid inputs, Confirm constructs `TrackConfiguration { totalDuration, clipStart, clipDuration, keyTimePercentages }` and triggers navigation to trimming.

- [X] T006 [US1] Model `TrackSettingsFeature.State` with raw `String` form fields and `destination` in `TrackSettingsFeature.swift`
- [X] T007 [US1] Implement `.confirmTapped` action and validation entrypoint in `TrackSettingsFeature.swift`
- [X] T008 [US1] Compute `clipDuration = totalDuration * (clipPercent/100)` (no internal rounding) in `TrackSettingsFeature.swift`
- [X] T009 [US1] Build `TrackConfiguration` and set navigation `destination` to trimming in `TrackSettingsFeature.swift`
- [X] T010 [US1] Wire `Confirm` button in `TrackSettingsView` to send `.confirmTapped`
- [X] T011 [US1] Render basic form fields with labels and helper text in `TrackSettingsView.swift`
- [X] T012 [P] [US1] Add navigation handoff to `AudioTrimmerView` using `NavigationStackStore` or equivalent state-driven navigation in `RootView.swift`
- [X] T013 [US1] Add `TrackSettingsTests` case: valid inputs produce expected `TrackConfiguration` and navigate in `Audio Trimmer/App/Tests/AppTests/TrackSettingsTests.swift`

---

## Phase 4: US2 – Inline validation and confirm disabling (P1)
Goal: Invalid submissions are blocked with clear inline errors; Confirm disabled while invalid.
Independent test criteria: Given invalid input(s), Confirm does not navigate and field-level errors are set.

- [ ] T014 [US2] Add per-field error storage and validation functions in `TrackSettingsFeature.swift`
- [ ] T015 [US2] Enforce rules: totalDuration > 0, clipPercent ∈ (0,100], clipStart ≥ 0, clipStart + clipDuration ≤ totalDuration in `TrackSettingsFeature.swift`
- [ ] T016 [US2] Disable Confirm when any field empty or any error present in `TrackSettingsView.swift`
- [ ] T017 [US2] Show inline error messages near fields in `TrackSettingsView.swift`
- [ ] T018 [US2] Add tests covering each invalid condition with assertions on errors and no navigation in `TrackSettingsTests.swift`

---

## Phase 5: US3 – Key times multiple input + normalization (P2)
Goal: Users can input multiple key times with normalization clamp→round(2)→sort→unique; empty after normalization is invalid.
Independent test criteria: Given raw key times (including whitespace/duplicates/boundaries), normalization yields expected list; empty after normalization blocks Confirm.

- [ ] T019 [US3] Parse `keyTimesText` into numeric list; ignore empty tokens in `TrackSettingsFeature.swift`
- [ ] T020 [US3] Normalize key times (clamp to [0,100], round(2), sort, unique) in `TrackSettingsFeature.swift`
- [ ] T021 [US3] Validate at least one normalized key time remains in `TrackSettingsFeature.swift`
- [ ] T022 [US3] Render token-like list preview or comma-joined normalized output in `TrackSettingsView.swift`
- [ ] T023 [US3] Add tests verifying normalization and invalid-empty behavior in `TrackSettingsTests.swift`

---

## Final Phase: Polish & Cross-Cutting

- [ ] T024 Add SwiftUI previews for common/edge cases in `TrackSettingsView.swift`
- [ ] T025 Ensure accessibility labels and hints on all fields and buttons in `TrackSettingsView.swift`
- [ ] T026 Review public exposure; keep feature internal unless needed; update doc comments where non-obvious in `TrackSettingsFeature.swift`
- [ ] T027 Update README with a short note linking to the new entry flow if needed in `/Users/mark/Audio-Trimmer/README.md`

---

## Parallel Execution Examples
- T012 (RootView navigation) can proceed in parallel with T006–T011 once feature skeleton exists (after T003–T005).
- UI work (T011, T016, T017, T022, T024–T025) can parallelize with reducer validations (T014–T021) after initial state/actions are defined.
- Tests (T013, T018, T023) can be drafted in parallel once reducer interfaces are stable (post T006–T009).

---

## Implementation Strategy (MVP First)
- MVP: Complete US1 (T006–T013). This delivers a usable entry screen that navigates to trimming with valid configurations.
- Next: US2 to harden validation UX and disable Confirm appropriately.
- Then: US3 to deliver multi-key-time normalization and display refinements.


