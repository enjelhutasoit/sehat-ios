//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SwiftUI

struct MedicationListScreen: View {
    let viewModel: MedicationListViewModel
    let refreshToken: Int
    let onAdd: @MainActor () -> Void

    var body: some View {
        content
            .navigationTitle(Strings.medication)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onAdd) {
                        Label(Strings.addReminder, systemImage: "plus")
                    }
                }
            }
            .task(id: refreshToken) { await viewModel.load() }
            .alert(Strings.couldntUpdateReminder, isPresented: failureBinding) {
                Button(Strings.ok) { viewModel.dismissFailure() }
            } message: {
                Text(Strings.tryAgain)
            }
    }

    private var failureBinding: Binding<Bool> {
        Binding(
            get: { viewModel.actionFailure != nil },
            set: { if !$0 { viewModel.dismissFailure() } }
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .accessibilityLabel(Strings.loading)
        case .failed:
            ContentUnavailableView {
                Label(Strings.couldntLoadReminders, systemImage: "exclamationmark.triangle")
            } actions: {
                Button(Strings.tryAgain) { Task { await viewModel.load() } }
            }
        case .loaded(let overview):
            loaded(overview)
        }
    }

    private func loaded(_ overview: ReminderOverview) -> some View {
        List {
            if overview.authorization == .denied {
                Section {
                    Text(Strings.notificationsAreOff)
                        .font(.footnote)
                }
            }
            Section {
                ForEach(overview.reminders) { reminder in
                    MedicationRow(reminder: reminder) { isEnabled in
                        Task { await viewModel.setEnabled(reminder, isEnabled: isEnabled) }
                    }
                    .swipeActions {
                        Button(Strings.delete, role: .destructive) {
                            Task { await viewModel.delete(reminder) }
                        }
                    }
                }
            } footer: {
                if overview.reminders.isEmpty {
                    Text(Strings.noRemindersYet)
                }
            }
        }
        .refreshable { await viewModel.load() }
    }
}
