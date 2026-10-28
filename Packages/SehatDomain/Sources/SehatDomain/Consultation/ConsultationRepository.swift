//
// Copyright (c) 2026 Enjel Hutasoit
//

import Foundation

/// Read access to consultations. Implemented by the data layer.
///
/// Contract: implementations throw `AppError` only (defined in `SehatCore`).
public protocol ConsultationRepository: Sendable {
    func consultations() async throws -> [Consultation]
    func consultation(id: Consultation.ID) async throws -> Consultation
}
