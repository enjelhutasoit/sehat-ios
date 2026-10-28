//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatAppointment
import SehatConsultation
import SwiftUI

@main
struct SehatApp: App {
    @State private var startup = Startup.loading

    var body: some Scene {
        WindowGroup {
            content
                .task { startup = await Startup.make() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch startup {
        case .loading:
            ProgressView()
        case .ready(let coordinators):
            TabView {
                ConsultationFlowView(coordinator: coordinators.consultation)
                    .tabItem { Label("Consultations", systemImage: "stethoscope") }
                AppointmentFlowView(coordinator: coordinators.appointment)
                    .tabItem { Label("Appointments", systemImage: "calendar") }
            }
        case .failed:
            ContentUnavailableView(
                "Can't open local data",
                systemImage: "exclamationmark.triangle",
                description: Text("Restart the app. The app did not delete anything.")
            )
        }
    }
}
