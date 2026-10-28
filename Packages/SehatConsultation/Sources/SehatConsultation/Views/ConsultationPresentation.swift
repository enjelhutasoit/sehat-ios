//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SwiftUI

// Temporary English literals. PR13 replaces them with string catalog lookups
// (id/en), using `AppError.localizationKey` for errors.

extension Consultation.Channel {
    var titleKey: LocalizedStringKey {
        switch self {
        case .chat: return "Chat"
        case .video: return "Video call"
        case .voice: return "Voice call"
        }
    }

    var symbolName: String {
        switch self {
        case .chat: return "message"
        case .video: return "video"
        case .voice: return "phone"
        }
    }
}

extension Consultation.Status {
    var titleKey: LocalizedStringKey {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

extension AppError {
    var messageKey: LocalizedStringKey {
        switch self {
        case .offline: return "No internet connection."
        case .timedOut: return "The request took too long. Try again."
        case .server: return "The server had a problem. Try again later."
        case .unauthorized: return "Your session has expired. Sign in again."
        case .notFound: return "This item could not be found."
        case .decoding: return "We couldn't read the data we received."
        case .storage: return "We couldn't read data stored on this device."
        case .cancelled: return "The operation was cancelled."
        case .unknown: return "Something went wrong."
        }
    }
}
