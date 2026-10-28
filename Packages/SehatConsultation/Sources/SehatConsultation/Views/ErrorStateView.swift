//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SwiftUI

struct ErrorStateView: View {
    let error: AppError
    let retry: @MainActor () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.messageKey)
        } actions: {
            Button("Try again") { retry() }
        }
    }
}
