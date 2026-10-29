//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SwiftUI

struct ConsultationRow: View {
    let consultation: Consultation

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var iconWidth: CGFloat = 28

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    summary
                    statusText
                }
            } else {
                HStack(spacing: 12) {
                    summary
                    Spacer()
                    statusText
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var summary: some View {
        HStack(spacing: 12) {
            Image(systemName: consultation.channel.symbolName)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(consultation.doctorName)
                    .font(.headline)
                Text(consultation.specialty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(consultation.scheduledAt, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusText: some View {
        Text(consultation.status.title)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    /// One spoken sentence per row: who, what, how, state, when.
    private var accessibilityText: String {
        [
            consultation.doctorName,
            consultation.specialty,
            consultation.channel.title,
            consultation.status.title,
            consultation.scheduledAt.formatted(date: .abbreviated, time: .shortened)
        ].joined(separator: ", ")
    }
}
