//
//  HistoryDashboardView.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-29.
//

import Foundation
import SwiftUI
import Charts

fileprivate func colorForScore(_ score: Double?) -> Color {
    guard let s = score else { return .gray }
    if s >= 85 { return .green }
    if s >= 65 { return .yellow }
    return .red
}

struct HistoryDashboardView: View {
    @StateObject private var vm: AssessmentHistoryViewModel

    init(viewModel: AssessmentHistoryViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView("Loading…")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let history = vm.history {
                    ScrollView {
                        VStack(spacing: 16) {
                            headerSection(history: history)
                            chartsSection(history: history)
                            assessmentList(history: history)
                        }
                        .padding()
                    }
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Text("Error")
                            .font(.title2).bold()
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await vm.load() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        Text("No data")
                    }
                }
            }
            .navigationTitle("Assessment History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await vm.load() }}) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            if vm.history == nil {
                await vm.load()
            }
        }
    }

    @ViewBuilder
    private func headerSection(history: AssessmentHistory) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(history.totalAssessments) assessments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                scoreCard(title: "Pronunciation", value: history.averagePronunciationScore)
                scoreCard(title: "Fluency", value: history.averageFluencyScore)
                scoreCard(title: "Accuracy", value: history.averageAccuracyScore)
                scoreCard(title: "Completeness", value: history.averageCompletenessScore)
            }
        }
    }

    private func scoreCard(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.0f", value))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: value, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: colorForScore(value)))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: Charts section
    @ViewBuilder
    private func chartsSection(history: AssessmentHistory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Over Time")
                .font(.headline)
            VStack(spacing: 16) {
                MetricChartView(metricName: "Pronunciation",
                                points: history.assessments.enumerated().map { (idx, a) in (idx+1, a.pronunciationScore) })
                MetricChartView(metricName: "Fluency",
                                points: history.assessments.enumerated().map { (idx, a) in (idx+1, a.fluencyScore) })
                MetricChartView(metricName: "Accuracy",
                                points: history.assessments.enumerated().map { (idx, a) in (idx+1, a.accuracyScore) })
                MetricChartView(metricName: "Completeness",
                                points: history.assessments.enumerated().map { (idx, a) in (idx+1, a.completenessScore) })
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func assessmentList(history: AssessmentHistory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Past Assessments")
                .font(.headline)
            ForEach(history.assessments.reversed()) { assessment in
                VStack(alignment: .leading, spacing: 8) {
                    Text(assessment.referenceText)
                        .font(.subheadline)
                        .lineLimit(2)
                    HStack(spacing: 12) {
                        miniScore(label: "P", value: assessment.pronunciationScore)
                        miniScore(label: "F", value: assessment.fluencyScore)
                        miniScore(label: "A", value: assessment.accuracyScore)
                        miniScore(label: "C", value: assessment.completenessScore)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
    }

    private func miniScore(label: String, value: Double) -> some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.subheadline).bold()
                .foregroundColor(colorForScore(value))
        }
        .frame(minWidth: 44)
    }
}

struct MetricChartView: View {
    var metricName: String
    var points: [(Int, Double)]  // (attempt, score)

    var body: some View {
        VStack(alignment: .leading) {
            Text(metricName)
                .font(.subheadline).bold()
            Chart {
                ForEach(points, id: \.0) { point in
                    LineMark(
                        x: .value("Attempt", point.0),
                        y: .value(metricName, point.1)
                    )
                    PointMark(
                        x: .value("Attempt", point.0),
                        y: .value(metricName, point.1)
                    )
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 140)
        }
    }
}

