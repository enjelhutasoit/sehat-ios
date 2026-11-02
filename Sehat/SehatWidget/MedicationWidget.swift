//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatWidgetSupport
import SwiftUI
import WidgetKit

struct MedicationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.medication, provider: MedicationProvider()) { entry in
            MedicationWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Next medication")
        .description("Shows when your next medication reminder is due.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct MedicationWidgetView: View {
    let entry: MedicationEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Next medication", systemImage: "pills")
                .font(family == .accessoryRectangular ? .caption2 : .caption)
                .foregroundStyle(.secondary)
            details
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var details: some View {
        switch entry.content {
        case .needsSetup:
            Text("Open Sehat to set up reminders.")
                .font(.footnote)
        case .noReminders:
            Text("No medication reminders")
                .font(.footnote)
        case .next(let name, let date):
            Text(date, style: .time)
                .font(.title2.bold())
            Text(name)
                .font(.footnote)
                .lineLimit(2)
                .privacySensitive()
        }
    }
}
