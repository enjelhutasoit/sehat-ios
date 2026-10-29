//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// The job a background refresh performs. Throwing means the job failed;
/// a cancelled job should stop and throw.
public protocol BackgroundWork: Sendable {
    func perform() async throws
}
