//
// Copyright (c) 2026 Enjel Hutasoit
//

import Observation
import SehatDomain

/// Owns navigation and builds view models for the consultation flow.
/// View models never navigate; they report events and the coordinator decides.
@MainActor
@Observable
public final class ConsultationCoordinator {
    var path: [ConsultationRoute] = []

    private let repository: any ConsultationRepository

    public init(repository: any ConsultationRepository) {
        self.repository = repository
    }

    func makeListViewModel() -> ConsultationListViewModel {
        ConsultationListViewModel(
            getOverview: GetConsultationOverviewUseCase(repository: repository),
            onSelect: { [weak self] id in self?.showDetail(id: id) }
        )
    }

    func makeDetailViewModel(id: Consultation.ID) -> ConsultationDetailViewModel {
        ConsultationDetailViewModel(consultationID: id, repository: repository)
    }

    func showDetail(id: Consultation.ID) {
        path.append(.detail(id))
    }
}
