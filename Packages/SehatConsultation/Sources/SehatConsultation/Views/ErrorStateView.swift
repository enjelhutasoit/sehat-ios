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
            Label(Strings.somethingWentWrong, systemImage: "exclamationmark.triangle")
        } description: {
            Text(Strings.message(for: error))
        } actions: {
            Button(Strings.tryAgain) { retry() }
        }
    }
}
