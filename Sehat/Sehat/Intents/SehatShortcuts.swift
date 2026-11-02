//
// Copyright (c) 2026 Enjel Hutasoit
//

import AppIntents

/// Phrases are English only: Indonesian phrases need a separate AppShortcuts
/// catalog, which is not part of this PR.
struct SehatShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextMedicationReminderIntent(),
            phrases: [
                "Next medication in \(.applicationName)",
                "When is my next medication in \(.applicationName)"
            ],
            shortTitle: "Next reminder",
            systemImageName: "pills"
        )
    }
}
