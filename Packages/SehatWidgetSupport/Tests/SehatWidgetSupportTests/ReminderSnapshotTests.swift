//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatWidgetSupport
import XCTest

final class ReminderSnapshotTests: XCTestCase {

    func test_encoded_producesStableJSON() throws {
        let snapshot = ReminderSnapshot(slots: [makeSlot(id: 1, name: "Paracetamol", hour: 8, minute: 5)])

        let json = String(decoding: try snapshot.encoded(), as: UTF8.self)

        XCTAssertEqual(
            json,
            #"{"slots":[{"hour":8,"id":"00000000-0000-0000-0000-000000000001","minute":5,"name":"Paracetamol"}],"version":1}"#
        )
    }

    func test_decode_roundTripsEncodedSnapshot() throws {
        let snapshot = ReminderSnapshot(slots: [makeSlot(id: 1), makeSlot(id: 2, name: "Vitamin C", hour: 20, minute: 30)])

        let decoded = try ReminderSnapshot.decode(try snapshot.encoded())

        XCTAssertEqual(decoded, snapshot)
    }

    func test_decode_acceptsAnEmptySnapshot() throws {
        let decoded = try ReminderSnapshot.decode(try ReminderSnapshot(slots: []).encoded())

        XCTAssertEqual(decoded.slots, [])
    }

    func test_decode_throwsDecoding_forAnUnknownVersion() {
        let data = Data(#"{"slots":[],"version":2}"#.utf8)

        assertDecodingFails(data)
    }

    func test_decode_throwsDecoding_forAnInvalidTime() {
        let data = Data(
            #"{"slots":[{"hour":24,"id":"00000000-0000-0000-0000-000000000001","minute":0,"name":"X"}],"version":1}"#.utf8
        )

        assertDecodingFails(data)
    }

    func test_decode_throwsDecoding_forGarbage() {
        assertDecodingFails(Data("not json".utf8))
        assertDecodingFails(Data())
    }

    func test_slot_isBuiltFromAReminderWithoutTheDosage() {
        let reminder = makeReminder(id: 3, name: "Aspirin", hour: 21, minute: 15)

        let slot = ReminderSlot(reminder)

        XCTAssertEqual(slot, makeSlot(id: 3, name: "Aspirin", hour: 21, minute: 15))
    }

    func test_slots_areOrderedByTime_thenName_thenID() {
        let ordered = [
            makeSlot(id: 9, name: "Z", hour: 7),
            makeSlot(id: 2, name: "A", hour: 8),
            makeSlot(id: 1, name: "B", hour: 8),
            makeSlot(id: 3, name: "B", hour: 8)
        ]

        XCTAssertEqual(ordered.shuffled().sorted(), ordered)
    }

    private func assertDecodingFails(_ data: Data, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try ReminderSnapshot.decode(data), file: file, line: line) { error in
            XCTAssertEqual(error as? AppError, .decoding, file: file, line: line)
        }
    }
}
