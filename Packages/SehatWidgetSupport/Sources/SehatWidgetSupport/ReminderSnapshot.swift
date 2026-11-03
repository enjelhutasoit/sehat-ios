//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation
import SehatCore
import SehatDomain

/// What the app tells the widget: the enabled reminders. Derived data; the
/// app rebuilds it whenever reminders change and at launch.
///
/// The JSON has sorted keys and a version number. A different version is
/// rejected instead of guessed.
public struct ReminderSnapshot: Sendable, Equatable {
    public static let currentVersion = 1

    public let slots: [ReminderSlot]

    public init(slots: [ReminderSlot]) {
        self.slots = slots
    }

    public func encoded() throws -> Data {
        let stored = Stored(
            version: Self.currentVersion,
            slots: slots.map {
                StoredSlot(id: $0.id, name: $0.medicationName, hour: $0.timeOfDay.hour, minute: $0.timeOfDay.minute)
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(stored)
    }

    /// - Throws: `AppError.decoding` for invalid JSON, another version, or an invalid time.
    public static func decode(_ data: Data) throws -> ReminderSnapshot {
        guard let stored = try? JSONDecoder().decode(Stored.self, from: data),
              stored.version == currentVersion
        else { throw AppError.decoding }

        var slots: [ReminderSlot] = []
        for item in stored.slots {
            guard let time = TimeOfDay(hour: item.hour, minute: item.minute) else {
                throw AppError.decoding
            }
            slots.append(ReminderSlot(id: item.id, medicationName: item.name, timeOfDay: time))
        }
        return ReminderSnapshot(slots: slots)
    }

    private struct Stored: Codable {
        let version: Int
        let slots: [StoredSlot]
    }

    private struct StoredSlot: Codable {
        let id: UUID
        let name: String
        let hour: Int
        let minute: Int
    }
}
