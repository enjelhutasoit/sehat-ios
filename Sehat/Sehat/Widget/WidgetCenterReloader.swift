//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatWidgetSupport
import WidgetKit

/// Thin adapter over WidgetCenter, verified manually.
struct WidgetCenterReloader: TimelineReloading {
    func reloadTimelines() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.medication)
    }
}
