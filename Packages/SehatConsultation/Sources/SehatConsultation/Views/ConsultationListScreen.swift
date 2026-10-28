//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SwiftUI

struct ConsultationListScreen: View {
    let viewModel: ConsultationListViewModel

    var body: some View {
        content
            .navigationTitle("Consultations")
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let error):
            ErrorStateView(error: error) {
                Task { await viewModel.load() }
            }
        case .loaded(let overview):
            if overview.isEmpty {
                ContentUnavailableView(
                    "No consultations",
                    systemImage: "stethoscope",
                    description: Text("Your consultations will appear here.")
                )
            } else {
                list(overview)
            }
        }
    }

    private func list(_ overview: ConsultationOverview) -> some View {
        List {
            if !overview.upcoming.isEmpty {
                Section("Upcoming") { rows(overview.upcoming) }
            }
            if !overview.history.isEmpty {
                Section("History") { rows(overview.history) }
            }
        }
        .refreshable { await viewModel.load() }
    }

    private func rows(_ consultations: [Consultation]) -> some View {
        ForEach(consultations) { consultation in
            Button {
                viewModel.select(consultation)
            } label: {
                ConsultationRow(consultation: consultation)
            }
        }
    }
}
