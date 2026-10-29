//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatBackground
import XCTest

final class BackgroundRefreshCoordinatorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 10_000)

    // MARK: - scheduleNextRefresh

    func test_scheduleNextRefresh_submitsRequestAfterMinimumInterval() throws {
        let submitter = SubmitterFake()
        let sut = makeSUT(submitter: submitter, interval: 900)

        try sut.scheduleNextRefresh()

        XCTAssertEqual(submitter.submittedDates, [Date(timeIntervalSince1970: 10_900)])
    }

    func test_scheduleNextRefresh_propagatesSubmitError() {
        let sut = makeSUT(submitter: SubmitterFake(failure: TestError()))

        XCTAssertThrowsError(try sut.scheduleNextRefresh()) { error in
            XCTAssertEqual(error as? TestError, TestError())
        }
    }

    func test_init_treatsInvalidIntervalAsZero() throws {
        for interval in [-5, .nan, .infinity] as [TimeInterval] {
            let submitter = SubmitterFake()

            try makeSUT(submitter: submitter, interval: interval).scheduleNextRefresh()

            XCTAssertEqual(submitter.submittedDates, [now], "interval: \(interval)")
        }
    }

    // MARK: - handleRefresh

    func test_handleRefresh_schedulesNextRefreshBeforeDoingWork_andCompletesWithSuccess() async {
        let log = EventLog()
        let handle = TaskHandleFake()
        let sut = makeSUT(submitter: SubmitterFake(log: log), work: WorkFake(log: log))

        await sut.handleRefresh(handle).value

        XCTAssertEqual(log.events, ["submit", "work"])
        XCTAssertEqual(handle.completions, [true])
    }

    func test_handleRefresh_installsExpirationHandler_beforeReturning() async {
        let handle = TaskHandleFake()
        let sut = makeSUT()

        let finished = sut.handleRefresh(handle)

        XCTAssertTrue(handle.hasExpirationHandler)
        await finished.value
    }

    func test_handleRefresh_completesWithFailure_whenWorkThrows() async {
        let handle = TaskHandleFake()
        let sut = makeSUT(work: WorkFake(failure: TestError()))

        await sut.handleRefresh(handle).value

        XCTAssertEqual(handle.completions, [false])
    }

    func test_handleRefresh_stillRunsWork_whenSchedulingFails() async {
        let work = WorkFake()
        let handle = TaskHandleFake()
        let sut = makeSUT(submitter: SubmitterFake(failure: TestError()), work: work)

        await sut.handleRefresh(handle).value

        let performed = await work.performCount
        XCTAssertEqual(performed, 1)
        XCTAssertEqual(handle.completions, [true])
    }

    func test_handleRefresh_expiration_cancelsWork_andCompletesOnceWithFailure() async {
        let work = UntilCancelledWork()
        let handle = TaskHandleFake()
        let sut = makeSUT(work: work)

        let finished = sut.handleRefresh(handle)
        await eventually { await work.isRunning }
        handle.fireExpiration()
        await finished.value

        let sawCancellation = await work.sawCancellation
        XCTAssertTrue(sawCancellation)
        XCTAssertEqual(handle.completions, [false])
    }

    func test_handleRefresh_expirationAfterCompletion_changesNothing() async {
        let handle = TaskHandleFake()
        let sut = makeSUT()
        await sut.handleRefresh(handle).value

        handle.fireExpiration()

        XCTAssertEqual(handle.completions, [true])
    }

    // MARK: - Helpers

    private func makeSUT(
        submitter: SubmitterFake = SubmitterFake(),
        work: any BackgroundWork = WorkFake(),
        interval: TimeInterval = 3_600
    ) -> BackgroundRefreshCoordinator {
        let now = self.now
        return BackgroundRefreshCoordinator(
            submitter: submitter,
            work: work,
            minimumInterval: interval,
            now: { now }
        )
    }
}
