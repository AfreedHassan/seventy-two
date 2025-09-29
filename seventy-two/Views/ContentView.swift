//
//  ContentView.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-24.
//

// local ip = 10.36.157.226

import SwiftUI
import SwiftData
import AVFoundation
import FirebaseAuth

struct AudioRecorderView: View {
    @StateObject private var audioManager = AudioManager()
    @Environment(\.colorScheme) var colorScheme
    @State private var showResults = false
    @State private var assessmentText = "Not Returned"
    @State private var isLoading = false
    let defaultPhrase = "She sells seashells by the seashore"
    @State private var userPhrase = ""
    @StateObject private var resultsVM = AssessmentViewModel()
    private let api = AssessmentAPI()
    
    var body: some View {
        VStack {
            NavigationStack {
                Spacer()
                Text("Say the following phrase:")
                    .padding(.vertical, 10)
                    .navigationTitle("Record")
                
                Text(defaultPhrase).font(.title)
                
                Text("or enter a phrase of your own").padding(.vertical, 30)
                
                TextField("Enter your phrase", text: $userPhrase)
                    .padding(12)
                    .background(Color(.systemGray6)) // light background for contrast
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .padding(.horizontal, 20)
                Spacer()
                VStack {
                    Text((isLoading ? "Loading...": ""))
                    if audioManager.isRecording { AudioVisualizerView() }
                    Button(action: {
                        Task {
                                audioManager.toggleRecordAudio()
                                
                                
                                if !audioManager.isRecording {
                                    do {
                                        isLoading = true
                                        if let uid = Auth.auth().currentUser?.uid {
                                            let phraseToUse = userPhrase.isEmpty ? defaultPhrase : userPhrase
                                            let id = try await api.uploadAudio(
                                                audioFilePath: audioManager.getAudioFilePath(),
                                                referenceText: phraseToUse,
                                                uid: uid
                                            )
                                            assessmentText = id
                                            await resultsVM.load(id: id)
                                            isLoading = false
                                            showResults = true
                                        }
                                    } catch {
                                        print("Upload failed: \(error)")
                                    }
                                }
                        }
                    }) {
                        ZStack() {
                            Circle().fill(Color.red).frame(width: 70, height: 70)
                            
                            if audioManager.isRecording {
                                Circle()
                                    .stroke((colorScheme == .dark ? Color.white : Color.black), lineWidth: 3)
                                    .frame(width: 85, height: 85)
                            }
                        }
                    }.padding(.vertical, 10)
                    
                    if (audioManager.isRecording) {
                        Text("Recording").font(.footnote)
                    }
                    Text("Microphone Access: \(audioManager.hasRecordingPermission ? "Granted": "Not Granted")")
                        .font(.footnote)
                        .padding(.bottom, 15)
                }.font(.title)
                    .navigationDestination(isPresented: $showResults) {
                        AssessmentResultsView(vm: resultsVM)
                    }
            }
        }
    }
}


struct ApiView : View {
    @State var jsonData : String = "Hello"
    
    nonisolated struct Joke : Codable {
        let joke: String
    }
    
    func getData() {
        // Define the URL you want to request
        //let APIUrlStr = "https://icanhazdadjoke.com/"
        //let APIUrlStr = "http://localhost:8080/api/assess"
        
        let APIUrlStr = "https://unmundified-whitley-uninfectiously.ngrok-free.dev/api/assess"
        
        if let apiUrl = URL(string: APIUrlStr) {
            print("URL OK")
            var req = URLRequest(url: apiUrl)
            req.httpMethod = "POST"
            
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            req.setValue("Seventy Two", forHTTPHeaderField: "User-Agent")
            
            let boundary = "Boundary-\(UUID().uuidString)"
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            let fileURL = URL(fileURLWithPath: "")
            let fileData = try! Data(contentsOf: fileURL)
            let filename = fileURL.lastPathComponent

            var data = Data()
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"audiofile\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            req.httpBody = data
            // Create a URLSession instance
            let session = URLSession.shared
            
            print("URL Session Created")
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
                    
                    jsonData = String(data: responseData, encoding: .utf8)!
                    
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
    }
    var body: some View {
        VStack {
            Button("Click me for a joke!", action: getData)
            
            Text(jsonData)
        }
    }
}


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var userSession: UserSession
    
    var body: some View {
        TabView{
            AudioRecorderView()
                .tabItem() {
                    Image(systemName: "microphone")
                    Text("Record")
                }
            HistoryDashboardView(viewModel: AssessmentHistoryViewModel(userId: "8fPF6t2pLQVy8P6G5uMyWUciT0Q2"))
                .tabItem() {
                    Image(systemName: "person.2.fill")
                    Text("History")
                }
                .padding(.vertical, 20)
        }
        //AudioRecorderView().preferredColorScheme(.dark)
        /*NavigationSplitView{
            AudioRecorderView().preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem() {
                    Button(action: doNothing) {
                        Label("Add Song", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select a song.")
        }
         */
    }
}


 #Preview {
 ContentView()
 .environmentObject(UserSession())
 }

