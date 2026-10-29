//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SwiftUI

struct ConsultationDetailScreen: View {
    @State private var viewModel: ConsultationDetailViewModel

    init(viewModel: ConsultationDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle(Strings.consultation)
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
        case .loaded(let consultation):
            details(consultation)
        }
    }

    private func details(_ consultation: Consultation) -> some View {
        List {
            LabeledContent(Strings.doctor, value: consultation.doctorName)
            LabeledContent(Strings.specialty, value: consultation.specialty)
            LabeledContent(Strings.channel, value: consultation.channel.title)
            LabeledContent(Strings.status, value: consultation.status.title)
            LabeledContent(Strings.date) {
                Text(consultation.scheduledAt, format: .dateTime.day().month().year().hour().minute())
            }
        }
    }
}
