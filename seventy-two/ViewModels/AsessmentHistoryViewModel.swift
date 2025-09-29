//
//  AsessmentHistoryViewModel.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-29.
//

import Foundation
import Combine

@MainActor
final class AssessmentHistoryViewModel: ObservableObject {
    @Published var history: AssessmentHistory?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let apiService: AssessmentAPI = AssessmentAPI()
    private let userId: String

    init(userId: String) {
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await apiService.getAssessmentHistory(userId: userId)
            // sort assessments by date ascending
            let sorted = fetched.assessments.sorted { $0.date < $1.date }
            let newHistory = AssessmentHistory(
                userId: fetched.userId,
                totalAssessments: fetched.totalAssessments,
                averagePronunciationScore: fetched.averagePronunciationScore,
                averageFluencyScore: fetched.averageFluencyScore,
                averageAccuracyScore: fetched.averageAccuracyScore,
                averageCompletenessScore: fetched.averageCompletenessScore,
                assessments: sorted
            )
            self.history = newHistory
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // Convenience: mock loader for previews or offline
}

// Small extension
fileprivate extension Collection where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
fileprivate extension Collection where Element == SummarisedAssessment {
    var averagePronunciation: Double { map { $0.pronunciationScore }.average }
}
