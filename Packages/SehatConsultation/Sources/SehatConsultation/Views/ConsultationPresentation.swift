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
