//
// Copyright (c) 2026 Enjel Hutasoit
//

import SwiftUI

/// Entry point of the consultation feature.
public struct ConsultationFlowView: View {
    @State private var coordinator: ConsultationCoordinator
    @State private var listViewModel: ConsultationListViewModel

    public init(coordinator: ConsultationCoordinator) {
        _coordinator = State(initialValue: coordinator)
        _listViewModel = State(initialValue: coordinator.makeListViewModel())
    }

    public var body: some View {
        @Bindable var bindableCoordinator = coordinator

        NavigationStack(path: $bindableCoordinator.path) {
            ConsultationListScreen(viewModel: listViewModel)
                .navigationDestination(for: ConsultationRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        ConsultationDetailScreen(viewModel: coordinator.makeDetailViewModel(id: id))
                    }
                }
        }
    }
}
