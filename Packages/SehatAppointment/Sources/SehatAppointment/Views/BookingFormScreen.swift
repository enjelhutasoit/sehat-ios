//
// Copyright (c) 2026 Enjel Hutasoit
//

import SwiftUI

struct BookingFormScreen: View {
    @State private var viewModel: BookingViewModel
    let onCancel: @MainActor () -> Void

    init(viewModel: BookingViewModel, onCancel: @escaping @MainActor () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onCancel = onCancel
    }

    var body: some View {
        @Bindable var form = viewModel

        NavigationStack {
            Form {
                Section("Doctor") {
                    TextField("Doctor name", text: $form.doctorName)
                    TextField("Specialty", text: $form.specialty)
                }
                Section("When") {
                    DatePicker(
                        "Starts at",
                        selection: $form.startsAt,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                if case .failed(let failure) = viewModel.phase {
                    Section {
                        Text(failure.messageKey)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Book appointment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Book") { Task { await viewModel.submit() } }
                        .disabled(viewModel.phase == .submitting)
                }
            }
        }
    }
}
