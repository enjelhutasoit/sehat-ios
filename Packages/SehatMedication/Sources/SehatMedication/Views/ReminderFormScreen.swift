//
// Copyright (c) 2026 Enjel Hutasoit
//

import SwiftUI

struct ReminderFormScreen: View {
    @State private var viewModel: ReminderFormViewModel
    let onCancel: @MainActor () -> Void

    init(viewModel: ReminderFormViewModel, onCancel: @escaping @MainActor () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onCancel = onCancel
    }

    var body: some View {
        @Bindable var form = viewModel

        NavigationStack {
            Form {
                Section("Medication") {
                    TextField("Name", text: $form.medicationName)
                    TextField("Dosage (for example, 1 tablet)", text: $form.dosage)
                }
                Section("Time") {
                    DatePicker("Every day at", selection: $form.time, displayedComponents: .hourAndMinute)
                }
                if case .failed(let failure) = viewModel.phase {
                    Section {
                        Text(failure.messageKey)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text("The notification shows a general message and never the medication name.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await viewModel.submit() } }
                        .disabled(viewModel.phase == .submitting)
                }
            }
        }
    }
}
