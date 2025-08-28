//
//  YouTubeViewModel.swift
//  YouTubePlaylistCreator
//
//  Created by Chris Lapointe
//  ViewModel handling YouTube API interactions and business logic
//

import SwiftUI
import Combine

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

enum MessageType {
    case success, error, info
}

enum VideoOrder: String, CaseIterable {
    case newestToOldest = "date"
    case oldestToNewest = "date_asc"
    case yearInTitleAsc = "year_in_title_asc"
    case yearInTitleDesc = "year_in_title_desc"
    case durationDesc = "duration_desc"
    case durationAsc = "duration_asc"
    case random = "random"

    var displayName: String {
        switch self {
        case .newestToOldest: return "Newest to Oldest"
        case .oldestToNewest: return "Oldest to Newest"
        case .random: return "Random"
        case .yearInTitleAsc: return "Year in Title (Oldest to Newest)"
        case .yearInTitleDesc: return "Year in Title (Newest to Oldest)"
        case .durationDesc: return "Longest to Shortest"
        case .durationAsc: return "Shortest to Longest"
        }
    }
}

struct YouTubeVideo: Identifiable {
    let id: String
    let title: String
    let description: String
    let duration: String
    let publishedAt: String
}

class YouTubeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var channelName = ""
    @Published var channelId = ""
    @Published var selectedOrder: VideoOrder = .newestToOldest
    @Published var keywordFilter = ""
    @Published var minDurationText = ""
    @Published var includeShorts = false
    @Published var videoIds: [String] = []
    @Published var videos: [YouTubeVideo] = []
    @Published var isLoading = false
    @Published var message: String?
    @Published var messageType: MessageType = .success

    // MARK: - Private Properties
    private let config: Config
    private var cancellables = Set<AnyCancellable>()

    init(config: Config) {
        self.config = config
    }

    // MARK: - Computed Properties
    var canFetchVideos: Bool {
        !config.apiKey.isEmpty && !channelId.isEmpty
    }



    var minDurationMinutes: Double? {
        guard !minDurationText.isEmpty else { return nil }
        return Double(minDurationText)
    }

    // MARK: - Public Methods
    func searchChannel() async {
        guard !channelName.isEmpty else {
            await MainActor.run {
                showMessage("Please enter a channel name", type: .error)
            }
            return
        }

        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            let searchUrl = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(channelName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=channel&key=\(config.apiKey)"

            guard let url = URL(string: searchUrl) else {
                throw URLError(.badURL)
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            let searchResponse = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)

            await MainActor.run {
                if let firstChannel = searchResponse.items.first {
                    channelId = firstChannel.id.channelId
                    showMessage("Found channel: \(firstChannel.snippet.title)")
                } else {
                    showMessage("No channel found with that name", type: .error)
                }
            }
        } catch {
            await MainActor.run {
                showMessage("Error searching for channel: \(error.localizedDescription)", type: .error)
            }
        }
    }

    func fetchVideos() async {
        guard canFetchVideos else {
            await MainActor.run {
                showMessage("Please enter API key and Channel ID", type: .error)
            }
            return
        }

        await MainActor.run {
            isLoading = true
            videoIds.removeAll()
            videos.removeAll()
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            // 1. Get channel uploads playlist
            let channelUrl = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails&id=\(channelId)&key=\(config.apiKey)"
            guard let channelURL = URL(string: channelUrl) else { throw URLError(.badURL) }

            let (channelData, _) = try await URLSession.shared.data(from: channelURL)
            let channelResponse = try JSONDecoder().decode(YouTubeChannelResponse.self, from: channelData)

            guard let uploadsPlaylistId = channelResponse.items.first?.contentDetails.relatedPlaylists.uploads else {
                throw NSError(domain: "YouTubeAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find uploads playlist"])
            }

            // 2. Fetch all video IDs from uploads playlist
            var allVideoIds: [String] = []
            var nextPageToken: String?

            repeat {
                let playlistUrl = "https://www.googleapis.com/youtube/v3/playlistItems?part=contentDetails&playlistId=\(uploadsPlaylistId)&maxResults=\(min(config.maxVideosLimit, 50))&pageToken=\(nextPageToken ?? "")&key=\(config.apiKey)"
                guard let playlistURL = URL(string: playlistUrl) else { throw URLError(.badURL) }

                let (playlistData, _) = try await URLSession.shared.data(from: playlistURL)
                let playlistResponse = try JSONDecoder().decode(YouTubePlaylistResponse.self, from: playlistData)

                let videoIds = playlistResponse.items.map { $0.contentDetails.videoId }
                allVideoIds.append(contentsOf: videoIds)

                nextPageToken = playlistResponse.nextPageToken
            } while nextPageToken != nil

            // 3. Fetch video details and apply filters
            var filteredVideos: [YouTubeVideo] = []

            for chunk in allVideoIds.chunked(into: 50) { // YouTube API limit is 50 per request
                let videoDetailsUrl = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails,snippet&id=\(chunk.joined(separator: ","))&key=\(config.apiKey)"
                guard let videoDetailsURL = URL(string: videoDetailsUrl) else { continue }

                let (videoDetailsData, _) = try await URLSession.shared.data(from: videoDetailsURL)
                let videoDetailsResponse = try JSONDecoder().decode(YouTubeVideoDetailsResponse.self, from: videoDetailsData)

                let validVideos = videoDetailsResponse.items.filter { video in
                    let totalSeconds = parseDuration(video.contentDetails.duration)
                    let isShort = totalSeconds <= 60

                    // Apply filters
                    if !includeShorts && isShort { return false }
                    if let minDuration = minDurationMinutes, totalSeconds < Int(minDuration * 60) { return false }

                    return true
                }

                filteredVideos.append(contentsOf: validVideos.map { item in
                    YouTubeVideo(
                        id: item.id,
                        title: item.snippet.title,
                        description: item.snippet.description,
                        duration: item.contentDetails.duration,
                        publishedAt: item.snippet.publishedAt
                    )
                })
            }

            // 4. Apply keyword filter
            if !keywordFilter.isEmpty {
                let keyword = keywordFilter.lowercased()
                filteredVideos = filteredVideos.filter { video in
                    video.title.lowercased().contains(keyword) ||
                    video.description.lowercased().contains(keyword)
                }
            }

            // 5. Sort videos
            sortVideos(&filteredVideos)

            // 6. Take first N videos based on user setting
            let finalVideos = Array(filteredVideos.prefix(config.maxVideosLimit))

            await MainActor.run {
                videos = finalVideos
                videoIds = finalVideos.map { $0.id }
                showMessage("Found \(finalVideos.count) videos")
            }

        } catch {
            await MainActor.run {
                showMessage("Error fetching videos: \(error.localizedDescription)", type: .error)
            }
        }
    }

    @MainActor
    func copyForIOS() {
        guard !videoIds.isEmpty else {
            showMessage("No video IDs to copy", type: .error)
            return
        }

        let iosUrl = "https://www.youtube.com/watch_videos?video_ids=\(videoIds.joined(separator: ","))"

        #if canImport(AppKit)
        // On Mac, copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(iosUrl, forType: .string)
        showMessage("URL copied to clipboard")
        #elseif canImport(UIKit)
        // On iOS, copy to clipboard
        UIPasteboard.general.string = iosUrl
        showMessage("URL copied to clipboard")
        #else
        showMessage("Clipboard not available on this platform", type: .error)
        #endif
    }

    @MainActor
    func openInYouTubeApp() {
        guard !videoIds.isEmpty else {
            showMessage("No video IDs to open", type: .error)
            return
        }

        let playlistUrl = "https://www.youtube.com/watch_videos?video_ids=\(videoIds.joined(separator: ","))"

        #if canImport(AppKit)
        // On Mac, open in default browser
        if let url = URL(string: playlistUrl) {
            NSWorkspace.shared.open(url)
            showMessage("Opened in browser")
        } else {
            showMessage("Unable to open URL", type: .error)
        }
        #elseif canImport(UIKit)
        // On iOS, try to open in YouTube app first, then fallback to browser
        let youtubeAppUrl = "youtube://watch_videos?video_ids=\(videoIds.joined(separator: ","))"
        let webUrl = playlistUrl

        if let youtubeURL = URL(string: youtubeAppUrl),
           UIApplication.shared.canOpenURL(youtubeURL) {
            UIApplication.shared.open(youtubeURL)
            showMessage("Opened in YouTube app")
        } else if let webURL = URL(string: webUrl) {
            UIApplication.shared.open(webURL)
            showMessage("Opened in browser")
        } else {
            showMessage("Unable to open playlist", type: .error)
        }
        #else
        showMessage("URL opening not available on this platform", type: .error)
        #endif
    }

    @MainActor
    func sharePlaylist() {
        guard !videoIds.isEmpty else {
            showMessage("No video IDs to share", type: .error)
            return
        }

        let playlistUrl = "https://www.youtube.com/watch_videos?video_ids=\(videoIds.joined(separator: ","))"

        #if targetEnvironment(macCatalyst)
        // On Mac, copy to clipboard for now
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(playlistUrl, forType: .string)
        showMessage("Playlist URL copied to clipboard")
        #else
        // On iOS, show share sheet
        // This would be implemented in the view using UIActivityViewController
        showMessage("Share functionality available on iOS")
        #endif
    }

    // MARK: - Private Methods
    @MainActor
    private func showMessage(_ text: String, type: MessageType = .success) {
        message = text
        messageType = type

        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            Task { @MainActor in
                self.message = nil
            }
        }
    }

    private func sortVideos(_ videos: inout [YouTubeVideo]) {
        switch selectedOrder {
        case .newestToOldest:
            videos.sort { $0.publishedAt > $1.publishedAt }
        case .oldestToNewest:
            videos.sort { $0.publishedAt < $1.publishedAt }
        case .random:
            videos.shuffle()
        case .yearInTitleAsc:
            videos.sort { extractYear($0.title) ?? Int.max < extractYear($1.title) ?? Int.max }
        case .yearInTitleDesc:
            videos.sort { extractYear($0.title) ?? Int.min > extractYear($1.title) ?? Int.min }
        case .durationDesc:
            videos.sort { parseDuration($0.duration) > parseDuration($1.duration) }
        case .durationAsc:
            videos.sort { parseDuration($0.duration) < parseDuration($1.duration) }
        }
    }

    private func parseDuration(_ duration: String) -> Int {
        let regex = try? NSRegularExpression(pattern: "PT(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?")
        let matches = regex?.matches(in: duration, range: NSRange(duration.startIndex..., in: duration))

        guard let match = matches?.first else { return 0 }

        // Safely extract hours, minutes, and seconds with bounds checking
        let hoursRange = match.range(at: 1)
        let hours = (hoursRange.location != NSNotFound && hoursRange.length > 0)
            ? Int((duration as NSString).substring(with: hoursRange)) ?? 0
            : 0

        let minutesRange = match.range(at: 2)
        let minutes = (minutesRange.location != NSNotFound && minutesRange.length > 0)
            ? Int((duration as NSString).substring(with: minutesRange)) ?? 0
            : 0

        let secondsRange = match.range(at: 3)
        let seconds = (secondsRange.location != NSNotFound && secondsRange.length > 0)
            ? Int((duration as NSString).substring(with: secondsRange)) ?? 0
            : 0

        return hours * 3600 + minutes * 60 + seconds
    }

    private func extractYear(_ title: String) -> Int? {
        let regex = try? NSRegularExpression(pattern: "\\b(19|20)\\d{2}\\b")
        let matches = regex?.matches(in: title, range: NSRange(title.startIndex..., in: title))

        guard let match = matches?.first else { return nil }

        let range = match.range
        guard range.location != NSNotFound && range.length > 0 else { return nil }

        return Int((title as NSString).substring(with: range))
    }
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - API Response Models
struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeSearchId
    let snippet: YouTubeSnippet
}

struct YouTubeSearchId: Codable {
    let channelId: String
}

struct YouTubeChannelResponse: Codable {
    let items: [YouTubeChannelItem]
}

struct YouTubeChannelItem: Codable {
    let contentDetails: YouTubeChannelContentDetails
}

struct YouTubeChannelContentDetails: Codable {
    let relatedPlaylists: YouTubeRelatedPlaylists
}

struct YouTubeRelatedPlaylists: Codable {
    let uploads: String
}

struct YouTubePlaylistResponse: Codable {
    let items: [YouTubePlaylistItem]
    let nextPageToken: String?
}

struct YouTubePlaylistItem: Codable {
    let contentDetails: YouTubePlaylistItemContentDetails
}

struct YouTubePlaylistItemContentDetails: Codable {
    let videoId: String
}

struct YouTubeVideoDetailsResponse: Codable {
    let items: [YouTubeVideoDetailsItem]
}

struct YouTubeVideoDetailsItem: Codable {
    let id: String
    let snippet: YouTubeSnippet
    let contentDetails: YouTubeContentDetails
}

struct YouTubeSnippet: Codable {
    let title: String
    let description: String
    let publishedAt: String
}

struct YouTubeContentDetails: Codable {
    let duration: String
}
