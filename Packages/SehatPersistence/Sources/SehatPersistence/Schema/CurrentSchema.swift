//
// Copyright (c) 2026 Enjel Hutasoit
//

/// The single place that names the newest schema. The rest of the package
/// uses these aliases and does not know which version they point to.
typealias CurrentSchema = SehatSchemaV3
typealias ConsultationRecord = CurrentSchema.ConsultationRecord
typealias OutboxRecord = CurrentSchema.OutboxRecord
typealias AppointmentRecord = CurrentSchema.AppointmentRecord
