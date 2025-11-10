## Feature: Track Settings Entry Page

### Overview
Add a new entry page for configuring audio track parameters before entering the trimming experience. Users input the total track length, key time percentages, clip start time, and clip percentage. Upon confirmation, the app navigates to the trimming screen with a configuration built from the inputs. Inputs are validated to prevent invalid states that would cause downstream issues.

### Goals
- Enable users to define a trimming session via a simple configuration form.
- Prevent invalid configurations through inline validation with clear error messaging.
- Seamlessly navigate to the trimming screen with a valid configuration.

### Non-Goals
- Audio playback or waveform visualization on the settings page.
- Persisting configurations across app launches.
- Advanced import/export flows.

### Actors
- Primary user: anyone preparing a track for trimming.

### Assumptions
- Time inputs are in seconds.
- Percentage inputs are in 0–100 inclusive, allowing up to two decimal places.
- Multiple key time percentages can be entered; they are displayed in ascending order and de-duplicated when equal after rounding to two decimals.
- Clip percentage represents the fraction of the total track to trim; it is converted to clip duration in seconds.

### Scope
- One screen that serves as the app entry point: “Track Settings”.
- A “Confirm” action that validates inputs and proceeds to the trimming screen.
- On success, the settings are converted into a configuration and passed forward.

### User Scenarios & Testing
1. Successful configuration
   - Given the user opens the app, when they enter:
     - Total track length: 120.0
     - Key times: 25, 75
     - Clip start: 10.0
     - Clip percent: 10
   - And they press Confirm, then they are navigated to the trimming screen and see:
     - Total duration 120s
     - Clip start 10s
     - Clip duration 12s (10% of 120)
     - Key times at 25% and 75%
2. Validation: key times out of range
   - Given key times include 101, when pressing Confirm, an inline error appears: “Key times must be between 0% and 100%.” Confirmation is blocked.
3. Validation: empty required fields
   - If total track length or clip percent is empty, show field-level error and block confirmation.
4. Validation: clip window exceeds track
   - Given total 30s, clip start 25s, clip percent 20% (clip duration 6s), pressing Confirm shows error: “Clip end exceeds track length. Adjust clip start or clip percent.” Confirmation is blocked.
5. Validation: zero or negative values
   - If total duration ≤ 0, show: “Track length must be greater than 0.”
   - If clip percent ≤ 0, show: “Clip percent must be greater than 0.”
6. Validation: key times required
   - If key times list is empty, show: “At least one key time is required.”
7. Input normalization
   - If the user enters key times with extra spaces or repeated values (e.g., 25, 25.0, 75), after normalization the unique sorted list [25, 75] is shown/used.

### Functional Requirements
- Entry screen fields (all required):
  - Track length (seconds): numeric, > 0.
  - Key times (%): one or more numeric values, each in [0, 100], allow up to two decimals; show as a tokenized list with ability to add/remove entries.
  - Clip start (seconds): numeric, ≥ 0.
  - Clip percent (% of total): numeric, > 0 and ≤ 100.
- Confirmation:
  - On Confirm, validate all fields. If any validation fails, do not proceed; display specific field-level errors and a general message if needed.
  - On success, compute clip duration in seconds as: clipDuration = totalDuration × (clipPercent ÷ 100). Round to two decimals for display; use the precise double value internally.
  - Validate clip window: clipStart + clipDuration ≤ totalDuration.
  - Normalize key times: round to two decimals for display, clamp to [0, 100], sort ascending, de-duplicate; if the resulting list is empty, block confirmation with an error.
  - Navigate to the trimming screen and pass the configuration.
- Accessibility and usability:
  - Show inline validation messages near fields.
  - Disable Confirm while required fields are empty or while errors are present.
  - Preserve user-entered values on validation failure.

### Validation Rules (business)
- Track length: must be present and > 0.
- Key times: at least one value; each ∈ [0, 100].
- Clip percent: ∈ (0, 100]; must produce clipDuration > 0.
- Clip start: ≥ 0 and clipStart + clipDuration ≤ totalDuration.
- Numeric inputs accept up to two decimal places; other characters are rejected or cause an error.

### Success Criteria
- 100% of invalid submissions show clear, field-specific error messages without navigating away.
- 95% of users can complete a valid configuration and proceed within 30 seconds (happy path).
- Navigation occurs within 1 second after a valid Confirm action on a typical device.
- The trimming screen always reflects the exact values implied by the inputs (no rounding errors visible beyond two decimal places in UI).

### Key Entities
- Configuration to pass forward contains:
  - totalDuration (seconds)
  - clipStart (seconds)
  - clipDuration (seconds; computed from clip percent)
  - keyTimePercentages (list of percentages as entered/normalized)

### Dependencies
- The trimming screen expects a configuration containing total duration, clip start, clip duration, and key time percentages.
- The entry page is the first screen shown when the app starts.

### Edge Cases
- Very short tracks (e.g., totalDuration < 1s): reject with validation stating track length must be > 0.
- clipPercent extremely small but > 0 leading to sub-second durations: allowed; ensure > 0 and within track bounds.
- Key times at boundaries (0, 100): allowed.
- Duplicate key times after rounding: de-duplicate before finalization; if the list becomes empty, block and show error.

### Out of Scope
- Persisting templates or history of configurations.
- Importing audio files or analyzing waveforms from this screen.

### Risks
- User confusion over clip percent vs. absolute duration; mitigate with helper text (e.g., “Clip percent is of total track length”).
- Precision/rounding mismatch between display and internal calculation; mitigate by consistent display rounding to two decimals and internal use of precise values.

### Acceptance Criteria
- Given valid inputs, pressing Confirm navigates to the trimming screen with the expected configuration values:
  - totalDuration equals Track length input
  - clipStart equals Clip start input
  - clipDuration equals totalDuration × (clipPercent ÷ 100)
  - keyTimePercentages equals the normalized list of key times
- Given any invalid input, pressing Confirm does not navigate and shows clear errors describing what to fix.

# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`  
**Created**: [DATE]  
**Status**: Draft  
**Input**: User description: "$ARGUMENTS"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently

  For each story, identify the reducers, actions, and effects involved, and describe
  how the Swift Composable Architecture `TestStore` will validate the flow before implementation.
  Include accessibility and performance acceptance criteria when user interactions are involved.
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- What happens when [boundary condition]?
- How does system handle [error scenario]?
- Are accessibility accommodations preserved when [assistive setting toggled]?
- What is the fallback when performance budget is exceeded by [long-running task]?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST [specific capability, e.g., "allow users to create accounts"]
- **FR-002**: System MUST [specific capability, e.g., "validate email addresses"]  
- **FR-003**: Users MUST be able to [key interaction, e.g., "reset their password"]
- **FR-004**: System MUST [data requirement, e.g., "persist user preferences"]
- **FR-005**: System MUST [behavior, e.g., "log all security events"]

*Example of marking unclear requirements:*

- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified - email/password, SSO, OAuth?]
- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Architecture & State Management *(mandatory)*

- **Feature Reducers**: List each `@Reducer` type, its `@ObservableState`, actions, effects, and scoping parent.
- **Dependencies**: Enumerate dependency clients required, including interfaces, failure handling, and test overrides.
- **Navigation**: Describe `NavigationStackStore`, `IfLetStore`, or `SwitchStore` usage and state-driven routing rules.
- **View Composition**: Identify SwiftUI views, shared components from `SharedUI`, and bindings back to `StoreOf<Feature>`.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: [Measurable metric, e.g., "Users can complete account creation in under 2 minutes"]
- **SC-002**: [Measurable metric, e.g., "System handles 1000 concurrent users without degradation"]
- **SC-003**: [User satisfaction metric, e.g., "90% of users successfully complete primary task on first attempt"]
- **SC-004**: [Business metric, e.g., "Reduce support tickets related to [X] by 50%"]
- **SC-005**: [Performance/observability metric, e.g., "Reducer completes waveform generation within 200 ms avg"]
- **SC-006**: [Accessibility metric, e.g., "All controls expose descriptive VoiceOver labels validated by tests"]
