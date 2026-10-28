//
// Copyright (c) 2026 Enjel Hutasoit
//

import SwiftUI

/// Entry point of the appointment feature.
public struct AppointmentFlowView: View {
    @State private var coordinator: AppointmentCoordinator
    @State private var listViewModel: AppointmentListViewModel

    public init(coordinator: AppointmentCoordinator) {
        _coordinator = State(initialValue: coordinator)
        _listViewModel = State(initialValue: coordinator.makeListViewModel())
    }

    public var body: some View {
        @Bindable var bindableCoordinator = coordinator

        NavigationStack {
            AppointmentListScreen(
                viewModel: listViewModel,
                refreshToken: coordinator.refreshToken,
                onBook: { coordinator.showBooking() }
            )
        }
        .sheet(isPresented: $bindableCoordinator.isPresentingBooking) {
            BookingFormScreen(
                viewModel: coordinator.makeBookingViewModel(),
                onCancel: { coordinator.cancelBooking() }
            )
        }
    }
}
