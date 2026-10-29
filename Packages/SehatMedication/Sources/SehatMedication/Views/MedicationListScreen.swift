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
            .navigationTitle("Medication")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onAdd) {
                        Label("Add reminder", systemImage: "plus")
                    }
                }
            }
            .task(id: refreshToken) { await viewModel.load() }
            .alert("Couldn't update the reminder", isPresented: failureBinding) {
                Button("OK") { viewModel.dismissFailure() }
            } message: {
                Text("Try again.")
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
        case .failed:
            ContentUnavailableView {
                Label("Couldn't load reminders", systemImage: "exclamationmark.triangle")
            } actions: {
                Button("Try again") { Task { await viewModel.load() } }
            }
        case .loaded(let overview):
            loaded(overview)
        }
    }

    private func loaded(_ overview: ReminderOverview) -> some View {
        List {
            if overview.authorization == .denied {
                Section {
                    Text("Notifications are off. Turn them on in Settings to receive reminders.")
                        .font(.footnote)
                }
            }
            Section {
                ForEach(overview.reminders) { reminder in
                    MedicationRow(reminder: reminder) { isEnabled in
                        Task { await viewModel.setEnabled(reminder, isEnabled: isEnabled) }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.delete(reminder) }
                        }
                    }
                }
            } footer: {
                if overview.reminders.isEmpty {
                    Text("No reminders yet. Add one with the plus button.")
                }
            }
        }
        .refreshable { await viewModel.load() }
    }
}
