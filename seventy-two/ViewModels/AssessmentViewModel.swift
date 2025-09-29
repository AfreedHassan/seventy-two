//
//  AssessmentViewModel.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-28.
//

import Foundation
import Combine

@MainActor
public class AssessmentViewModel: ObservableObject {
    @Published public var assessment: Assessment?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    private let api: AssessmentAPI
    
    public init() {
        self.api = AssessmentAPI()
    }
    
    // Load an assessment by id. 
    public func load(id: String) async {
        self.isLoading = true
        self.errorMessage = nil
        defer { self.isLoading = false }
        
        do {
            let fetched = try await api.fetchAssessment(id: id)
            self.assessment = fetched
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // reload if we already have an id in the assessment
    public func reloadCurrent() async {
        guard let id = assessment?.id else { return }
        await load(id: id)
    }
}
