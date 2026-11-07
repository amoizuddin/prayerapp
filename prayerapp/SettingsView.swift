import SwiftUI

/// Alert preferences: which prayers' alerts are Time Sensitive.
struct SettingsView: View {
    /// Called after any change so alerts can be re-lined up.
    var onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var timeSensitive: [Prayer: Bool] = Dictionary(
        uniqueKeysWithValues: AlertSettings.alertPrayers.map { ($0, AlertSettings.isTimeSensitive($0)) }
    )

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(AlertSettings.alertPrayers, id: \.self) { prayer in
                        Toggle(prayer.name, isOn: binding(for: prayer))
                    }
                } header: {
                    Text("Time Sensitive Alerts")
                } footer: {
                    Text("Time Sensitive alerts come through Focus modes like Sleep and Do Not Disturb.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func binding(for prayer: Prayer) -> Binding<Bool> {
        Binding(
            get: { timeSensitive[prayer] ?? true },
            set: { value in
                timeSensitive[prayer] = value
                AlertSettings.setTimeSensitive(prayer, value)
                onChange()
            }
        )
    }
}

#Preview {
    SettingsView(onChange: {})
}
