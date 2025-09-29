//
//  AudioManager.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-26.
//

import AVFoundation
import Combine

final class AudioManager : ObservableObject {
    @Published var hasRecordingPermission: Bool = false
    @Published var isRecording: Bool = false
    @Published var recordings: [URL] = []
    @Published var assessmentID: String = "No assessment"
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioFilePath: URL?
    
    init(audioRecorder: AVAudioRecorder? = nil, audioPlayer: AVAudioPlayer? = nil, audioFilePath: URL? = nil) {
        self.audioRecorder = nil
        self.audioPlayer = nil
        self.audioFilePath = nil
        self.requestRecordingPermission()
        try? setupAudioSession()
    }
    
    func getAudioFilePath() -> URL {
        return self.audioFilePath!
    }
    
    func getRecordings() -> [URL] {
        setRecordings()
        return recordings
    }
    
    func toggleRecordAudio() {
        if self.isRecording {
            self.stopRecording()
        } else {
            if self.hasRecordingPermission {
                self.requestRecordingPermission()
            }
            if self.hasRecordingPermission {
                do {
                    try self.setupAudioSession()
                    try self.setupRecorder()
                    self.startRecording()
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    func getAssessment() {
        let id = self.assessmentID
        let apiUrlStr = "http://localhost:8080/api/assess/\(id)"
        if let apiUrl = URL(string: apiUrlStr) {
            var req = URLRequest(url: apiUrl)
            req.httpMethod = "GET"
            
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("Seventy Two", forHTTPHeaderField: "User-Agent")
            
            let session = URLSession.shared
            print("URL Session Created")
            
            session.dataTask(with: req) { (data, response, error) in
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        print("Response JSON: \(String(describing: json))")
                    } catch {
                        print("JSON parse error: \(error.localizedDescription)")
                    }
                }
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                }
            }.resume()
        }
    }
    
    func uploadAudioForAssessment() {
        // Define the URL you want to request
        //let APIUrlStr = "https://icanhazdadjoke.com/"
        //let APIUrlStr = "http://localhost:8080/api/assess"
        let apiUrlStr = "https://unmundified-whitley-uninfectiously.ngrok-free.dev/api/assess"
        
        //let filename = self.audioFilePath?.lastPathComponent
        if let apiUrl = URL(string: apiUrlStr) {
            var req = URLRequest(url: apiUrl)
            req.httpMethod = "POST"
            
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("Seventy Two", forHTTPHeaderField: "User-Agent")
            
            let boundary = "Boundary-\(UUID().uuidString)"
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let fileData = try! Data(contentsOf: audioFilePath!)
            let filename = self.audioFilePath!.lastPathComponent
            
            var data = Data()
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            req.httpBody = data
            // Create a URLSession instance
            let session = URLSession.shared
            print("URL Session Created")
            
            session.dataTask(with: req) { (data, response, error) in
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
                        if json?["status"] == "success" {
                            self.assessmentID = json!["id"]!
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                if let error = error {
                    print(error.localizedDescription)
                }
            }.resume()
        }
    }
            /*
            // Create a data task using URLSessionDataTask
            Task {
                print("In Task")
                let dataTask = session.dataTask(with: req) { (data, response, error) in
                    // Handle the response
                    print("Doing task")
                    
                    // Check for errors
                    if error != nil {
                        print("Error: \(String(describing: error))")
                        return
                    }
                    
                    // Check if data is available
                    guard let responseData = data else {
                        print("No data received")
                        return
                    }
                    
                    //jsonData = String(data: responseData, encoding: .utf8)!
                    
                    // Process the received data
                    /*
                     do {
                     let decoder = JSONDecoder()
                     //let joke = try decoder.decode(Joke.self, from: data!)
                     //jsonData = joke.joke
                     if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                     print("Response JSON: \(json)")
                     if let joke = json["joke"] as? String {
                     print("Joke: \(joke)")
                     }
                     }
                     } catch {
                     print("Error parsing JSON: \\(error)")
                     }
                     */
                }
                dataTask.resume()
            }
        } else {
            print("URL is not valid!")
        }
             */
    private func startRecording() {
        try? self.setupRecorder()
        if (self.audioRecorder?.record() ?? false) {
            self.isRecording = true
        }
    }

    private func stopRecording() {
        if (self.isRecording && (self.audioRecorder?.stop() != nil)) {
            self.isRecording = false
        }
        do {
            if self.doesAudioFileExist(filePathURL: self.audioFilePath!) {
                self.audioPlayer = try AVAudioPlayer(contentsOf: self.audioFilePath!)
                //self.uploadAudioForAssessment()
                self.recordings.append(self.audioFilePath!)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } else {
                print("Audio file does not exist")
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    private func requestRecordingPermission() {
        Task {
            self.hasRecordingPermission = await AVAudioApplication.requestRecordPermission()
        }
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? audioSession.setActive(true)
    }
    
    private func setupRecorder() throws {
        let recordingSettings = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue] as [String : Any]
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.audioFilePath = documentPath.appendingPathComponent("recording\(self.recordings.count+1).wav")
        
        self.audioRecorder = try AVAudioRecorder(url: self.audioFilePath!, settings: recordingSettings)
        self.audioRecorder?.prepareToRecord()
    }
    
    private func doesAudioFileExist(filePathURL: URL) -> Bool {
        if FileManager.default.fileExists(atPath: filePathURL.path) {
            return true
        }
        return false
    }
    
    private func setRecordings() {
        do {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)
            for recording in contents {
                print(recording.relativeString)
                self.recordings.append(recording)
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
    }
}
