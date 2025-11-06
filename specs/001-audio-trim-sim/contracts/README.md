# Contracts: Audio Trim Simulator

This feature operates entirely within a local TCA reducer and does not expose network or persistence APIs. No REST or GraphQL contracts are required. Future UI layers will interact via `StoreOf<AudioTrimmerFeature>` actions and bindings only.
