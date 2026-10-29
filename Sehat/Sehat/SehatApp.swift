//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatAppointment
import SehatConsultation
import SehatMedication
import SwiftUI

@main
struct SehatApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var startup = Startup.loading

    init() {
        // Must happen before the app finishes launching.
        BackgroundRefresh.register()
        DiagnosticsSetup.start()
    }

    var body: some Scene {
        WindowGroup {
            content
                .task { startup = await Startup.make() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                BackgroundRefresh.scheduleNextRefresh()
            }
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
                MedicationFlowView(coordinator: coordinators.medication)
                    .tabItem { Label("Medication", systemImage: "pills") }
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
