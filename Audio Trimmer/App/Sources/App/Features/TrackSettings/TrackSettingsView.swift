import SwiftUI
import ComposableArchitecture

struct TrackSettingsView: View {
    @Bindable var store: StoreOf<TrackSettingsFeature>
    
    init(store: StoreOf<TrackSettingsFeature>) {
        self.store = store
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Track Settings")
                    .font(.title)
                    .bold()
                
                VStack(alignment: .leading, spacing: 16) {
                    LabeledField(
                        label: "Track length (seconds)",
                        text: $store.totalDurationText
                    )
                    if let error = store.totalDurationError {
                        FieldError(text: error)
                    }
                    
                    LabeledField(
                        label: "Key times (%) · comma or space separated",
                        keyboardType: .default,
                        text: $store.keyTimesText
                    )
                    if let error = store.keyTimesError {
                        FieldError(text: error)
                    }
                    
                    LabeledField(
                        label: "Clip start (seconds)",
                        text: $store.clipStartText
                    )
                    if let error = store.clipStartError {
                        FieldError(text: error)
                    }
                    
                    LabeledField(
                        label: "Clip percent (% of total)",
                        text: $store.clipPercentText
                    )
                    if let error = store.clipPercentError {
                        FieldError(text: error)
                    }
                }
                
                Button {
                    store.send(.confirmTapped)
                } label: {
                    Label("Confirm", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.isConfirmEnabled)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
    }
}

private enum FieldKeyboardType {
    case numberPad
    case `default`
}

private struct LabeledField: View {
    let label: String
    let keyboardType: FieldKeyboardType
    @Binding var text: String
    
    init(label: String, keyboardType: FieldKeyboardType = .numberPad, text: Binding<String>) {
        self.label = label
        self.keyboardType = keyboardType
        self._text = text
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
            textField
        }
    }
    
    @ViewBuilder
    private var textField: some View {
        #if os(iOS)
        switch keyboardType {
        case .numberPad:
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        case .default:
            TextField("", text: $text)
                .keyboardType(.default)
                .textFieldStyle(.roundedBorder)
        }
        #else
        TextField("", text: $text)
            .textFieldStyle(.roundedBorder)
        #endif
    }
}

private struct FieldError: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.red)
    }
}

#Preview {
    TrackSettingsView(
        store: Store(
            initialState: TrackSettingsFeature.State()
        ) {
            TrackSettingsFeature()
        }
    )
}


