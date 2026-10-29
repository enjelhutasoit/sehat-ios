//
// Copyright (c) 2026 Enjel Hutasoit
//

import SwiftUI

/// Entry point of the medication feature.
public struct MedicationFlowView: View {
    @State private var coordinator: MedicationCoordinator
    @State private var listViewModel: MedicationListViewModel

    public init(coordinator: MedicationCoordinator) {
        _coordinator = State(initialValue: coordinator)
        _listViewModel = State(initialValue: coordinator.makeListViewModel())
    }

    public var body: some View {
        @Bindable var bindableCoordinator = coordinator

        NavigationStack {
            MedicationListScreen(
                viewModel: listViewModel,
                refreshToken: coordinator.refreshToken,
                onAdd: { coordinator.showForm() }
            )
        }
        .sheet(isPresented: $bindableCoordinator.isPresentingForm) {
            ReminderFormScreen(
                viewModel: coordinator.makeFormViewModel(),
                onCancel: { coordinator.cancelForm() }
            )
        }
    }
}
