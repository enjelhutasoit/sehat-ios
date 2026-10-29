//
// Copyright (c) 2026 Enjel Hutasoit
//

import SehatCore
import SehatDomain
import SwiftUI

extension Consultation.Channel {
    var title: String {
        switch self {
        case .chat: return Strings.chat
        case .video: return Strings.videoCall
        case .voice: return Strings.voiceCall
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
    var title: String {
        switch self {
        case .scheduled: return Strings.scheduled
        case .inProgress: return Strings.inProgress
        case .completed: return Strings.completed
        case .cancelled: return Strings.cancelled
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
