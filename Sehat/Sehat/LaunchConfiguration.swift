//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Launch arguments used by UI tests. A normal launch has none of them.
struct LaunchConfiguration {
    /// Use a separate store instead of the real one.
    let isUITesting: Bool
    /// Empty the UI-testing store at launch. Only honored together with `isUITesting`.
    let resetsUITestingData: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        isUITesting = arguments.contains("-ui-testing")
        resetsUITestingData = arguments.contains("-ui-testing-reset")
    }
}
