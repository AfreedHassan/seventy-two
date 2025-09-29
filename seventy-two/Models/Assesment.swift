//
//  Models.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-28.
//

import Foundation

// Top-level assessment model
public struct Assessment: Codable, Identifiable {
    public let id: String?
    public let recognitionStatus: String?
    public let offset: Int64?      // ticks (100-ns)
    public let duration: Int64?    // ticks
    public let channel: Int?
    public let displayText: String?
    public let referenceText: String?
    public let snr: Double?
    public let nBest: [NBest]?
    
    public var identifier: String? { id } // convenience
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case recognitionStatus = "RecognitionStatus"
        case offset = "Offset"
        case duration = "Duration"
        case channel = "Channel"
        case displayText = "DisplayText"
        case referenceText = "ReferenceText"
        case snr = "SNR"
        case nBest = "NBest"
    }
    
    public var firstNBest: NBest? {
        return nBest?.first
    }
}

public struct NBest: Codable {
    public let confidence: Double?
    public let lexical: String?
    public let itn: String?
    public let maskedITN: String?
    public let display: String?
    public let pronunciationAssessment: PronunciationAssessment?
    public let words: [Word]?
    
    enum CodingKeys: String, CodingKey {
        case confidence = "Confidence"
        case lexical = "Lexical"
        case itn = "ITN"
        case maskedITN = "MaskedITN"
        case display = "Display"
        case pronunciationAssessment = "PronunciationAssessment"
        case words = "Words"
    }
}

// Generic pronunciation assessment used in multiple places.
// Some have only AccuracyScore; others include FluencyScore etc.
public struct PronunciationAssessment: Codable {
    public let accuracyScore: Double?
    public let fluencyScore: Double?
    public let completenessScore: Double?
    public let pronScore: Double?
    public let errorType: String?   // e.g. "Insertion", "Omission", "None"
    
    enum CodingKeys: String, CodingKey {
        case accuracyScore = "AccuracyScore"
        case fluencyScore = "FluencyScore"
        case completenessScore = "CompletenessScore"
        case pronScore = "PronScore"
        case errorType = "ErrorType"
    }
}

// Word item
public struct Word: Codable {
    public let word: String?
    public let offset: Int64?
    public let duration: Int64?
    public let pronunciationAssessment: PronunciationAssessment?
    public let syllables: [Syllable]?
    public let phonemes: [Phoneme]?
    
    enum CodingKeys: String, CodingKey {
        case word = "Word"
        case offset = "Offset"
        case duration = "Duration"
        case pronunciationAssessment = "PronunciationAssessment"
        case syllables = "Syllables"
        case phonemes = "Phonemes"
    }
}

// Syllable
public struct Syllable: Codable {
    public let syllable: String?
    public let grapheme: String?
    public let pronunciationAssessment: PronunciationAssessment?
    public let offset: Int64?
    public let duration: Int64?
    
    enum CodingKeys: String, CodingKey {
        case syllable = "Syllable"
        case grapheme = "Grapheme"
        case pronunciationAssessment = "PronunciationAssessment"
        case offset = "Offset"
        case duration = "Duration"
    }
}

// Phoneme
public struct Phoneme: Codable {
    public let phoneme: String?
    public let pronunciationAssessment: PronunciationAssessment?
    public let offset: Int64?
    public let duration: Int64?
    
    enum CodingKeys: String, CodingKey {
        case phoneme = "Phoneme"
        case pronunciationAssessment = "PronunciationAssessment"
        case offset = "Offset"
        case duration = "Duration"
    }
}

// helper to convert from previews and ticks to seconds
extension Assessment {
    // Convert 100-ns ticks to seconds (Double)
    public static func seconds(fromTicks ticks: Int64?) -> Double? {
        guard let t = ticks else { return nil }
        return Double(t) / 10_000_000.0
    }
}
