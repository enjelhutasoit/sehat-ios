//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import XCTest

final class LoadStateTests: XCTestCase {
    private typealias State = LoadState<Int>

    func test_startingLoad_showsLoading_whenThereIsNoContent() {
        XCTAssertEqual(State.idle.startingLoad(), .loading)
        XCTAssertEqual(State.loading.startingLoad(), .loading)
        XCTAssertEqual(State.failed(.offline).startingLoad(), .loading)
    }

    func test_startingLoad_keepsContentVisible() {
        XCTAssertEqual(State.loaded(1).startingLoad(), .loaded(1))
    }

    func test_afterFailure_returnsFailedWithMappedError() {
        let result = State.afterFailure(URLError(.timedOut), restoring: .idle)

        XCTAssertEqual(result, .failed(.timedOut))
    }

    func test_afterFailure_restoresPreviousState_onCancellation() {
        let previousStates: [State] = [.idle, .loaded(3), .failed(.storage)]

        for previous in previousStates {
            XCTAssertEqual(State.afterFailure(CancellationError(), restoring: previous), previous)
            XCTAssertEqual(State.afterFailure(AppError.cancelled, restoring: previous), previous)
        }
    }

    func test_value_isNilUnlessLoaded() {
        XCTAssertNil(State.idle.value)
        XCTAssertNil(State.failed(.unknown).value)
        XCTAssertEqual(State.loaded(7).value, 7)
    }
}
