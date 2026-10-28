//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatDomain
import SwiftUI

struct ConsultationRow: View {
    let consultation: Consultation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: consultation.channel.symbolName)
                .frame(width: 28)
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

            Spacer()

            Text(consultation.status.titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
