//
//  AssessmentResultsView.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-28.
//

import Foundation
import SwiftUI

fileprivate extension Double {
    // clamp 0...100
    func normalized() -> Double {
        return min(max(self, 0.0), 100.0)
    }
}

fileprivate func colorForScore(_ score: Double?) -> Color {
    guard let s = score else { return .gray }
    let val = s
    if val >= 85 { return .green }
    if val >= 65 { return .yellow }
    return .red
}

fileprivate func secondsString(fromTicks ticks: Int64?) -> String {
    guard let ticks = ticks else { return "-" }
    let seconds = Double(ticks) / 10_000_000.0
    return String(format: "%.2f s", seconds)
}

fileprivate struct ScoreChip: View {
    let title: String
    let score: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.footnote)
                    .bold()
                Spacer()
                Text(score.map { String(format: "%.0f", $0) + "%" } ?? "-")
                    .font(.footnote)
                    .monospacedDigit()
                    .bold()
            }
            ProgressView(value: (score ?? 0) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: colorForScore(score)))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .cornerRadius(6)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

fileprivate struct WordRowView: View {
    let word: Word
    @State private var expanded: Bool = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 8) {
                // Syllables
                if let syllables = word.syllables, !syllables.isEmpty {
                    Text("Syllables")
                        .font(.subheadline)
                        .bold()
                    ForEach(Array(syllables.enumerated()), id: \.offset) { idx, s in
                        HStack {
                            Text(s.syllable ?? s.grapheme ?? "-")
                                .font(.body)
                            Spacer()
                            Text(s.pronunciationAssessment?.accuracyScore.map { String(format: "%.0f%%", $0) } ?? "-")
                                .font(.subheadline)
                                .bold()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(secondsString(fromTicks: s.offset))
                                    .font(.caption2)
                                Text(secondsString(fromTicks: s.duration))
                                    .font(.caption2)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color(.systemBackground).opacity(0.001)) // for accessibility tap
                    }
                }
                
                // Phonemes
                if let phonemes = word.phonemes, !phonemes.isEmpty {
                    Text("Phonemes")
                        .font(.subheadline)
                        .bold()
                    ForEach(Array(phonemes.enumerated()), id: \.offset) { idx, p in
                        HStack {
                            Text(p.phoneme ?? "-")
                                .font(.body)
                            Spacer()
                            Text(p.pronunciationAssessment?.accuracyScore.map { String(format: "%.0f%%", $0) } ?? "-")
                                .font(.subheadline)
                                .bold()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(secondsString(fromTicks: p.offset))
                                    .font(.caption2)
                                Text(secondsString(fromTicks: p.duration))
                                    .font(.caption2)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                    }
                }
            }
            .padding(.vertical, 6)
        } label: {
            HStack {
                Text(word.word ?? "-")
                    .font(.body)
                    .bold()
                Spacer()
                // accuracy
                if let acc = word.pronunciationAssessment?.accuracyScore {
                    Text(String(format: "%.0f%%", acc))
                        .font(.body)
                        .bold()
                        .foregroundColor(colorForScore(acc))
                } else {
                    Text("-")
                }
                
                // Error badge
                if let err = word.pronunciationAssessment?.errorType, err.lowercased() != "none" {
                    Text(err)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
        }
        .animation(.easeInOut, value: expanded)
    }
}

public struct AssessmentResultsView: View {
    @StateObject public var vm: AssessmentViewModel
    
    // init with an existing VM (e.g. created in caller)
    public init(vm: AssessmentViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    // convenience init from id: will create a VM and fetch on appear/task
    public init(id: String, api: AssessmentAPI) {
        let vm = AssessmentViewModel()
        _vm = StateObject(wrappedValue: vm)
        // load will be triggered via .task in body
        Task {
            // no-op here, actual fetch in .task below (to avoid calling async in init)
        }
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView("Loading assessment…")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Text("Error")
                            .font(.title2).bold()
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                if let id = vm.assessment?.id {
                                    await vm.load(id: id)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let assessment = vm.assessment {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Summary Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Phrase:").font(.title3)
                                Text(assessment.referenceText!)
                                    .font(.subheadline)
                                    .bold()
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                                
                                Grid() {
                                    let pa = assessment.firstNBest?.pronunciationAssessment
                                    GridRow {
                                        ScoreChip(title: "Accuracy", score: pa?.accuracyScore)
                                        ScoreChip(title: "Fluency", score: pa?.fluencyScore)
                                    }
                                    GridRow {
                                        ScoreChip(title: "Completeness", score: pa?.completenessScore)
                                        ScoreChip(title: "Pronunciation", score: pa?.pronScore)
                                    }
                                }
                            }
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(14)
                            .shadow(radius: 2)
                            
                            // Transcript (selectable)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Transcript")
                                    .font(.headline)
                                Text(assessment.firstNBest?.display ?? assessment.displayText ?? "-")
                                    .textSelection(.enabled)
                                    .font(.body)
                            }
                            
                            // Words list
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Words")
                                        .font(.headline)
                                    Spacer()
                                    if let words = assessment.firstNBest?.words {
                                        Text("\(words.count)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                if let words = assessment.firstNBest?.words, !words.isEmpty {
                                    LazyVStack(spacing: 8, pinnedViews: []) {
                                        ForEach(Array(words.enumerated()), id: \.offset) { idx, w in
                                            WordRowView(word: w)
                                                .padding(.horizontal, 4)
                                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                                .cornerRadius(10)
                                        }
                                    }
                                } else {
                                    Text("No words data available.")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                    .navigationTitle("Assessment Results")
                    .navigationBarTitleDisplayMode(.inline)
                } else {
                    Text("No assessment loaded.")
                        .foregroundColor(.secondary)
                }
            }
            .task {
                // If VM has no assessment and an id exists, try to load it.
                if vm.assessment == nil {
                    // Attempt to load if a placeholder id exists in vm.assessment, or do nothing.
                    // In typical use, caller should call vm.load(id:).
                }
            }
            .onAppear {
                // nothing here; view expects caller to either:
                // - pass a VM with assessment already set, or
                // - create the vm and call vm.load(id:) before presenting, or
                // - the caller can call Task { await vm.load(id: id) } after presenting.
            }
        }
    }
}
