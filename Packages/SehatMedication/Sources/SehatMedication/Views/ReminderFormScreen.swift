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
                Section(Strings.medication) {
                    TextField(Strings.name, text: $form.medicationName)
                    TextField(Strings.dosagePlaceholder, text: $form.dosage)
                }
                Section(Strings.time) {
                    DatePicker(Strings.everyDayAt, selection: $form.time, displayedComponents: .hourAndMinute)
                }
                if case .failed(let failure) = viewModel.phase {
                    Section {
                        Text(failure.message)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text(Strings.notificationPrivacyNote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Strings.newReminder)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.cancel, action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.save) { Task { await viewModel.submit() } }
                        .disabled(viewModel.phase == .submitting)
                }
            }
        }
    }
}
