//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SwiftUI

struct AppointmentRow: View {
    let appointment: Appointment

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    details
                    statusLabel
                }
            } else {
                HStack(spacing: 12) {
                    details
                    Spacer()
                    statusLabel
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(appointment.doctorName)
                .font(.headline)
            Text(appointment.specialty)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(appointment.startsAt, format: .dateTime.day().month().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusLabel: some View {
        Label(appointment.status.title, systemImage: appointment.status.symbolName)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var accessibilityText: String {
        [
            appointment.doctorName,
            appointment.specialty,
            appointment.status.title,
            appointment.startsAt.formatted(date: .abbreviated, time: .shortened)
        ].joined(separator: ", ")
    }
}
