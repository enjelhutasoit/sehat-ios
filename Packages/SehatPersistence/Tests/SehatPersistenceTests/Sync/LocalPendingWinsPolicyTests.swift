//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatPersistence
import XCTest

final class LocalPendingWinsPolicyTests: XCTestCase {

    func test_resolve_returnsAllRemote_whenNothingIsPending() {
        let remote = [makeConsultation(id: 1), makeConsultation(id: 2)]

        let result = LocalPendingWinsPolicy().resolve(remote: remote, pendingEntityIDs: [])

        XCTAssertEqual(result, remote)
    }

    func test_resolve_dropsRemoteItemsThatHavePendingLocalChanges() {
        let kept = makeConsultation(id: 2)
        let remote = [makeConsultation(id: 1), kept, makeConsultation(id: 3)]

        let result = LocalPendingWinsPolicy().resolve(
            remote: remote,
            pendingEntityIDs: [makeUUID(1), makeUUID(3)]
        )

        XCTAssertEqual(result, [kept])
    }

    func test_resolve_returnsEmpty_whenRemoteIsEmpty() {
        let result = LocalPendingWinsPolicy().resolve(remote: [], pendingEntityIDs: [makeUUID(1)])

        XCTAssertTrue(result.isEmpty)
    }
}
