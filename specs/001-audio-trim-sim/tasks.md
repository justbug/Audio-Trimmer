# Tasks: Simulated Audio Trimming Demo

**Input**: Design documents from `/specs/001-audio-trim-sim/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Reducer and dependency tests are REQUIRED. Only omit when the specification explicitly documents an exception approved by maintainers.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared scaffolding required by all stories

- [ ] T001 Verify `Audio Trimmer/App/Package.swift` pins The Composable Architecture 1.23.0 and Swift `Testing` dependencies needed for the feature.
- [ ] T002 Create feature directory structure `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/` with placeholder `AudioTrimmerFeature.swift`.
- [ ] T003 Add `Audio Trimmer/App/Tests/AppTests/AudioTrimmerTests.swift` with empty test case suite referencing the new reducer.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Define `TrackConfiguration`, `PlaybackSimulation`, and `TimelineSnapshot` structs with `TimeInterval` fields and validation stubs in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.
- [ ] T005 Declare `AudioTrimmerFeature.Action`, `@ObservableState`, and cancellation token (`TimerID`) scaffolding in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.
- [ ] T006 Provide initial dummy state factory (e.g., `AudioTrimmerFeature.State.preview`) and dependency requirement stubs in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Configure and Play Clip Simulation (Priority: P1) 🎯 MVP

**Goal**: Simulate countdown playback for a configured clip while deriving absolute key time markers.

**Independent Test**: `AudioTrimmerTests` drives `.playTapped` and `.tick` actions using an `ImmediateClock`, asserting countdown reaches zero and status transitions idle → playing → finished with accurate marker projections.

### Tests for User Story 1 (REQUIRED) ⚠️

- [ ] T007 [P] [US1] Author failing tests covering `.playTapped` countdown progression in `Audio Trimmer/App/Tests/AppTests/AudioTrimmerTests.swift`.
- [ ] T008 [P] [US1] Add tests validating timeline marker derivation and configuration validation in `Audio Trimmer/App/Tests/AppTests/AudioTrimmerTests.swift`.

### Implementation for User Story 1

- [ ] T009 [US1] Implement configuration validation helpers and timeline projection updates in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.
- [ ] T010 [US1] Implement `.playTapped` effect pipeline, `.tick` handler, and completion state transitions in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.
- [ ] T011 [US1] Populate dummy track configuration defaults surfaced via public initialiser in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.

**Checkpoint**: User Story 1 fully functional and testable independently

---

## Phase 4: User Story 2 - Pause and Resume Simulation (Priority: P2)

**Goal**: Allow playback to pause and resume without losing progress, cancelling and restarting timer effects deterministically.

**Independent Test**: `AudioTrimmerTests` verifies `.pauseTapped` cancels scheduled ticks and `.resumeTapped` restarts from stored state without double-counting.

### Tests for User Story 2 (REQUIRED) ⚠️

- [ ] T012 [P] [US2] Extend tests to assert timer cancellation on pause and precise resume behaviour in `Audio Trimmer/App/Tests/AppTests/AudioTrimmerTests.swift`.

### Implementation for User Story 2

- [ ] T013 [US2] Implement `.pauseTapped` reducing logic cancelling the timer effect and freezing countdown in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.
- [ ] T014 [US2] Implement `.resumeTapped` logic re-establishing the timer effect from stored state in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.

**Checkpoint**: User Stories 1 and 2 functional and independently testable

---

## Phase 5: User Story 3 - Adjust Markers and Clip Window (Priority: P3)

**Goal**: Support editing clip boundaries and key time percentages with immediate validation and timeline updates.

**Independent Test**: `AudioTrimmerTests` covers `.updateClipStart`, `.updateClipDuration`, and `.updateKeyTimes` ensuring normalized percentages, bounded clip windows, and warning flags.

### Tests for User Story 3 (REQUIRED) ⚠️

- [ ] T015 [P] [US3] Create tests for configuration editing actions and validation warnings in `Audio Trimmer/App/Tests/AppTests/AudioTrimmerTests.swift`.

### Implementation for User Story 3

- [ ] T016 [US3] Implement clip editing actions enforcing `clipStart + clipDuration <= totalDuration` in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.
- [ ] T017 [US3] Implement key time normalization, deduplication, and derived marker recalculation in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.
- [ ] T018 [US3] Surface configuration error/warning collection in state for future UI consumption in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.

**Checkpoint**: All user stories functional and independently testable

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T019 [P] Run `swift test --package-path "Audio Trimmer/App" --filter AudioTrimmerTests` and document results in `specs/001-audio-trim-sim/quickstart.md`.
- [ ] T020 Review reducer documentation/comments and ensure idiomatic access control in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.
- [ ] T021 [P] Capture any additional instrumentation or logging hooks for timer drift analysis in `Audio Trimmer/App/Sources/App/Features/AudioTrimmer/AudioTrimmerFeature.swift`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → prerequisite for Foundational.
- **Foundational (Phase 2)** → prerequisite for all User Story phases.
- **User Story Phases (3–5)** → may proceed sequentially (P1 → P2 → P3) or in parallel after Phase 2, provided shared files are coordinated.
- **Polish (Phase 6)** → occurs after targeted user stories reach completion.

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2; provides baseline playback logic used by subsequent stories.
- **US2 (P2)**: Builds on US1’s playback loop; requires US1 completion to reuse state/actions.
- **US3 (P3)**: Depends on US1 foundational configuration structures; may be developed after US1 once shared helpers exist.

### Parallel Opportunities

- Marked `[P]` tasks (e.g., T007, T008, T012, T015, T019, T021) target distinct concerns or files and can run concurrently when file change conflicts are managed.
- After foundational scaffolding, US2 and US3 test authoring can begin in parallel while US1 implementation finishes, provided coordination on shared reducer file sections.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phases 1–2 to establish scaffolding.
2. Deliver Phase 3 tasks (tests then implementation) to achieve countdown playback.
3. Validate via `swift test --filter AudioTrimmerTests` before expanding scope.

### Incremental Delivery

1. MVP (US1) → Demo playable countdown.
2. Add US2 pause/resume controls → Demo responsiveness.
3. Add US3 configuration editing → Demo full configurability.
4. Polish with instrumentation and documentation updates.

### Parallel Team Strategy

1. Shared foundation (Phases 1–2) completed collaboratively.
2. Assign US1 implementation to Developer A, US2 test authoring to Developer B, and US3 validation logic to Developer C, coordinating reducer merge boundaries.
3. Conduct integration test run (Phase 6) once all stories merge.

