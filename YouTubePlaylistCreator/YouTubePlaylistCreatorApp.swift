//
//  YouTubePlaylistCreatorApp.swift
//  YouTubePlaylistCreator
//
//  Created by Chris LaPointe on 8/28/25.
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
