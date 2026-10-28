//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SwiftUI

struct AppointmentListScreen: View {
    let viewModel: AppointmentListViewModel
    let refreshToken: Int
    let onBook: @MainActor () -> Void

    var body: some View {
        content
            .navigationTitle("Appointments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onBook) {
                        Label("Book appointment", systemImage: "plus")
                    }
                }
            }
            .task(id: refreshToken) { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .failed:
            ContentUnavailableView {
                Label("Couldn't load appointments", systemImage: "exclamationmark.triangle")
            } actions: {
                Button("Try again") { Task { await viewModel.load() } }
            }
        case .loaded(let appointments):
            if appointments.isEmpty {
                ContentUnavailableView(
                    "No appointments",
                    systemImage: "calendar",
                    description: Text("Book one with the plus button.")
                )
            } else {
                List(appointments) { AppointmentRow(appointment: $0) }
                    .refreshable { await viewModel.load() }
            }
        }
    }
}
