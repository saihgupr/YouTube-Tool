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
    @AppStorage("maxVideosLimit") private var storedMaxVideos = 50

    var apiKey: String {
        get {
            return storedApiKey
        }
        set {
            storedApiKey = newValue
        }
    }

    var maxVideosLimit: Int {
        get { storedMaxVideos }
        set { storedMaxVideos = newValue }
    }

    var hasCustomApiKey: Bool {
        !storedApiKey.isEmpty
    }

    func resetToDefault() {
        storedApiKey = ""
    }
}
