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
            .navigationTitle("Consultation")
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
        case .loaded(let consultation):
            details(consultation)
        }
    }

    private func details(_ consultation: Consultation) -> some View {
        List {
            LabeledContent("Doctor", value: consultation.doctorName)
            LabeledContent("Specialty", value: consultation.specialty)
            LabeledContent("Channel") { Text(consultation.channel.titleKey) }
            LabeledContent("Status") { Text(consultation.status.titleKey) }
            LabeledContent("Date") {
                Text(consultation.scheduledAt, format: .dateTime.day().month().year().hour().minute())
            }
        }
    }
}
