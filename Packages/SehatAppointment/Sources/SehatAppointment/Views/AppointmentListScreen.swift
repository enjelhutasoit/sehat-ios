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
            .navigationTitle(Strings.appointments)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: onBook) {
                        Label(Strings.bookAppointment, systemImage: "plus")
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
                .accessibilityLabel(Strings.loading)
        case .failed:
            ContentUnavailableView {
                Label(Strings.couldntLoadAppointments, systemImage: "exclamationmark.triangle")
            } actions: {
                Button(Strings.tryAgain) { Task { await viewModel.load() } }
            }
        case .loaded(let appointments):
            if appointments.isEmpty {
                ContentUnavailableView(
                    Strings.noAppointments,
                    systemImage: "calendar",
                    description: Text(Strings.noAppointmentsDescription)
                )
            } else {
                List(appointments) { AppointmentRow(appointment: $0) }
                    .refreshable { await viewModel.load() }
            }
        }
    }
}
