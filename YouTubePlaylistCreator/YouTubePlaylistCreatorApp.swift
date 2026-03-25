//
//  YouTubePlaylistCreatorApp.swift
//  YouTubePlaylistCreator
//
//

import SwiftUI

@main
struct YouTubePlaylistCreatorApp: App {
    @StateObject private var config = Config()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(config)
                .preferredColorScheme(.dark)
        }
    }
}
