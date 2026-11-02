//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatWidgetSupport
import WidgetKit

struct MedicationEntry: TimelineEntry {
    let date: Date
    let content: WidgetContent

    /// Sample shown in the widget gallery.
    static let placeholder = MedicationEntry(
        date: .now,
        content: .next(medicationName: "Paracetamol", at: .now.addingTimeInterval(3_600))
    )
}
