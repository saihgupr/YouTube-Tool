//
//  Config.swift
//  YouTubePlaylistCreator
//
//  Created by Chris Lapointe
//  Configuration management for API keys and settings
//

import SwiftUI

class Config: ObservableObject {
    @AppStorage("youtubeApiKey") private var storedApiKey = ""

    var apiKey: String {
        get {
            return storedApiKey
        }
        set {
            storedApiKey = newValue
        }
    }

    var maxVideosLimit: Int {
        return 50 // Fixed default value
    }

    var hasCustomApiKey: Bool {
        !storedApiKey.isEmpty
    }

    func resetToDefault() {
        storedApiKey = ""
    }
}
