//
//  Item.swift
//  seventy-two
//
//  Created by Mir Afreed Hassan on 2025-09-24.
//

import Foundation
import SwiftData

@Model
final class Song {
    var name: String
    var artist: String

    init(name: String, artist: String) {
        self.name = name
        self.artist = artist
    }
}
