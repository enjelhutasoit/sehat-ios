//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SwiftUI

struct MedicationRow: View {
    let reminder: MedicationReminder
    let onToggle: @MainActor (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding(get: { reminder.isEnabled }, set: { onToggle($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.medicationName)
                    .font(.headline)
                Text(reminder.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(reminder.timeOfDay.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
