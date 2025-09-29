//
//  AssessmentHistory.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-29.
//

import Foundation

struct AssessmentHistory: Codable {
    let userId: String
    let totalAssessments: Int
    let averagePronunciationScore: Double
    let averageFluencyScore: Double
    let averageAccuracyScore: Double
    let averageCompletenessScore: Double
    let assessments: [SummarisedAssessment]
}

struct SummarisedAssessment: Codable, Identifiable {
    var id: UUID { UUID() } // Replace with backend ID if available

    let referenceText: String
    let pronunciationScore: Double
    let fluencyScore: Double
    let accuracyScore: Double
    let completenessScore: Double
    let date: Double   // just keep the raw numeric value
}
