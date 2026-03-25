//
//  Config.swift
//  YouTubePlaylistCreator
//
//  Configuration management for API keys and settings
//

import SwiftUI

class Config: ObservableObject {
    @AppStorage("youtubeApiKey") private var storedApiKey = ""
    @AppStorage("autoOpenYouTubeLinks") private var storedAutoOpenLinks = false
    @AppStorage("showChannelIdInput") private var storedShowChannelIdInput = false

    var apiKey: String {
        get {
            return storedApiKey
        }
        set {
            storedApiKey = newValue
        }
    }

    var autoOpenYouTubeLinks: Bool {
        get {
            return storedAutoOpenLinks
        }
        set {
            storedAutoOpenLinks = newValue
        }
    }

    var showChannelIdInput: Bool {
        get {
            return storedShowChannelIdInput
        }
        set {
            storedShowChannelIdInput = newValue
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
