//
//  ContentView.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-24.
//

import SwiftUI
import SwiftData

struct SongForm : View {
    @Binding var songName: String
    @Binding var songArtist: String
    @Binding var showTextArea: Bool
    var addSong: (_: String, _: String) -> Void

    var body: some View {
        Form {
            TextField("Enter song name", text:$songName)
            TextField("Enter artist name", text:$songArtist)
        }.onSubmit {
            addSong(songName, songArtist)
            songName = ""
            songArtist = ""
            showTextArea.toggle()
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var songs: [Song] = [
        Song(name: "Juna", artist:"Clairo"),
        Song(name: "Slow Dancing In A Burning Room", artist:"John Mayer"),
    ]
    
    @State private var songName = ""
    @State private var songArtist = ""
    @State private var showTextArea = false
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(songs) { song in
                    NavigationLink {
                        Text("\(song.name)")
                            .font(.largeTitle)
                        Text("by \(song.artist)")
                    } label: {
                        Text(" \(song.name)")
                    }
                }
                .onDelete(perform: deleteSong)
                .navigationTitle("Songs")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem() {
                    Button(action: textInput) {
                        Label("Add Song", systemImage: "plus")
                    }
                }
            }
            
            if showTextArea {
                withAnimation {
                    SongForm(songName: $songName, songArtist: $songArtist, showTextArea: $showTextArea, addSong: addSong)
                }
            }
        } detail: {
            Text("Select a song.")
        }
        
    }
    
    private func textInput() {
        showTextArea.toggle()
    }
    
    private func addSong(
        name: String = "Slow Dancing in a Burning Room",
        artist: String = "John Mayer") {
            
            withAnimation {
                let newSong = Song(name: name, artist: artist)
                modelContext.insert(newSong)
                try? modelContext.save()
            }
        }
    private func deleteSong(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(songs[index])
                try? modelContext.save()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Song.self)
}
