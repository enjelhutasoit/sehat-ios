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
                Section(Strings.doctor) {
                    TextField(Strings.doctorName, text: $form.doctorName)
                    TextField(Strings.specialty, text: $form.specialty)
                }
                Section(Strings.when) {
                    DatePicker(
                        Strings.startsAt,
                        selection: $form.startsAt,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                if case .failed(let failure) = viewModel.phase {
                    Section {
                        Text(failure.message)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(Strings.bookAppointment)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.cancel, action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.book) { Task { await viewModel.submit() } }
                        .disabled(viewModel.phase == .submitting)
                }
            }
        }
    }
}
