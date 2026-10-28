//
// Copyright (c) 2026 Enjel Hutasoit
//

import Observation
import SehatDomain

@MainActor
@Observable
final class ConsultationDetailViewModel {
    private(set) var state: LoadState<Consultation> = .idle

    private let consultationID: Consultation.ID
    private let repository: any ConsultationRepository

    init(consultationID: Consultation.ID, repository: any ConsultationRepository) {
        self.consultationID = consultationID
        self.repository = repository
    }

    func load() async {
        let previous = state
        state = previous.startingLoad()
        do {
            state = .loaded(try await repository.consultation(id: consultationID))
        } catch {
            state = .afterFailure(error, restoring: previous)
        }
    }
}
