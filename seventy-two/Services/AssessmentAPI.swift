//
//  AsessmentAPI.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-28.
//

import Foundation

public enum AssessmentAPIError: LocalizedError {
    case serverError(statusCode: Int, data: Data?)
    case invalidResponse
    case decodingError(Error)
    case other(Error)
    
    public var errorDescription: String? {
        switch self {
        case .serverError(let status, _):
            return "Server responded with status code \(status)."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingError(let e):
            return "Failed to decode server response: \(e.localizedDescription)"
        case .other(let e):
            return e.localizedDescription
        }
    }
}

public struct UploadResponse: Codable {
    public let status: String?
    public let message: String?
    public let id: String?
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case message = "message"
        case id = "id"
    }
}

public final class AssessmentAPI {
    public let baseURL: URL = URL(string: "https://unmundified-whitley-uninfectiously.ngrok-free.dev")!
    
    // Uploads a .wav file to POST /api/assess (multipart form field "file")
    // Returns the returned id string on success.
    func uploadAudio(audioFilePath: URL, referenceText: String, uid: String) async throws -> String {
        var assessmentID : String = ""
        
        //let filename = self.audioFilePath?.lastPathComponent
        let apiUrl = baseURL.appendingPathComponent("api/assess")
        var req = URLRequest(url: apiUrl)
        req.httpMethod = "POST"
        
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Seventy Two", forHTTPHeaderField: "User-Agent")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let fileData = try Data(contentsOf: audioFilePath)
        let filename = audioFilePath.lastPathComponent
        
        var reqBody = Data()
        
        reqBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        reqBody.append("Content-Disposition: form-data; name=\"uid\"\r\n\r\n".data(using: .utf8)!)
        reqBody.append("\(uid)\r\n".data(using: .utf8)!)
        
        reqBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        reqBody.append("Content-Disposition: form-data; name=\"referenceText\"\r\n\r\n".data(using: .utf8)!)
        reqBody.append("\(referenceText)\r\n".data(using: .utf8)!)
        
        reqBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        reqBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        reqBody.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        reqBody.append(fileData)
        reqBody.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        req.httpBody = reqBody
        let (data, _) = try await URLSession.shared.data(for: req)
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String,
               status == "success",
               let id = json["id"] as? String {
                return id
            } else {
                throw URLError(.badServerResponse)
        }
        /*
        print("URL Session Created")
        
        session.dataTask(with: req) { (data, response, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
                    if json?["status"] == "success" {
                        assessmentID = json!["id"]!
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            if let error = error {
                print(error.localizedDescription)
            }
        }.resume()
         */
    }
    
    func getAssessmentHistory(userId: String) async throws -> AssessmentHistory {
            // construct URL
            let url = baseURL.appendingPathComponent("api/assessments/\(userId)")

            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.setValue("application/json", forHTTPHeaderField: "Accept")

            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    throw AssessmentAPIError.invalidResponse
                }

                let decoder = JSONDecoder()
                // We'll not set decoder.dateDecodingStrategy because SummirisedAssessment handles its own parsing
                let history = try decoder.decode(AssessmentHistory.self, from: data)
                return history
            } catch let decodeError as DecodingError {
                throw AssessmentAPIError.decodingError(decodeError)
            } catch {
                throw AssessmentAPIError.other(error)
            }
        }
    
    // Fetch the full assessment JSON:
    // GET /api/assess/{id}
    public func fetchAssessment(id: String) async throws -> Assessment {
        let endpoint = baseURL.appendingPathComponent("/api/result/\(id)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                print(response)
                throw AssessmentAPIError.invalidResponse
            }
            guard (200...299).contains(http.statusCode) else {
                print(response)
                throw AssessmentAPIError.serverError(statusCode: http.statusCode, data: data)
            }
            do {
                let decoder = JSONDecoder()
                let assessment = try decoder.decode(Assessment.self, from: data)
                return assessment
            } catch {
                throw AssessmentAPIError.decodingError(error)
            }
        } catch {
            throw AssessmentAPIError.other(error)
        }
    }
}

// data helper
fileprivate extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


