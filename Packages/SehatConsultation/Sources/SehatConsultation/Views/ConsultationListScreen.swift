//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SwiftUI

struct ConsultationListScreen: View {
    let viewModel: ConsultationListViewModel

    var body: some View {
        content
            .navigationTitle(Strings.consultations)
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .accessibilityLabel(Strings.loading)
        case .failed(let error):
            ErrorStateView(error: error) {
                Task { await viewModel.load() }
            }
        case .loaded(let overview):
            if overview.isEmpty {
                ContentUnavailableView(
                    Strings.noConsultations,
                    systemImage: "stethoscope",
                    description: Text(Strings.noConsultationsDescription)
                )
            } else {
                list(overview)
            }
        }
    }

    private func list(_ overview: ConsultationOverview) -> some View {
        List {
            if !overview.upcoming.isEmpty {
                Section(Strings.upcoming) { rows(overview.upcoming) }
            }
            if !overview.history.isEmpty {
                Section(Strings.history) { rows(overview.history) }
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
            .accessibilityHint(Strings.opensConsultationDetails)
        }
    }
}
