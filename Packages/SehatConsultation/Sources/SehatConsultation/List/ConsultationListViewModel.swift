//
// Copyright (c) 2026 Enjel Hutasoit
//

import Observation
import SehatDomain

@MainActor
@Observable
final class ConsultationListViewModel {
    private(set) var state: LoadState<ConsultationOverview> = .idle

    @ObservationIgnored private var isLoadInFlight = false
    private let getOverview: GetConsultationOverviewUseCase
    private let onSelect: @MainActor (Consultation.ID) -> Void

    init(
        getOverview: GetConsultationOverviewUseCase,
        onSelect: @escaping @MainActor (Consultation.ID) -> Void
    ) {
        self.getOverview = getOverview
        self.onSelect = onSelect
    }

    /// Loads the overview. A call made while another load runs is ignored.
    func load() async {
        guard !isLoadInFlight else { return }
        isLoadInFlight = true
        defer { isLoadInFlight = false }

        let previous = state
        state = previous.startingLoad()
        do {
            state = .loaded(try await getOverview.execute())
        } catch {
            state = .afterFailure(error, restoring: previous)
        }
    }

    func select(_ consultation: Consultation) {
        onSelect(consultation.id)
    }
}
