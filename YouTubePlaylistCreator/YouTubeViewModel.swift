//
//  YouTubeViewModel.swift
//  YouTubePlaylistCreator
//
//  ViewModel handling YouTube API interactions and business logic
//

import SwiftUI
import Combine

#if canImport(AppKit)
import AppKit
import Foundation
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
        case .yearInTitleAsc: return "Year in Title (Oldest to Newest)"
        case .yearInTitleDesc: return "Year in Title (Newest to Oldest)"
        case .durationDesc: return "Longest to Shortest"
        case .durationAsc: return "Shortest to Longest"
        case .random: return "Random"
        }
    }
    
    static var sortedCases: [VideoOrder] {
        return allCases.filter { $0 != .random } + [.random]
    }
}

struct YouTubeVideo: Identifiable {
    let id: String
    let title: String
    let description: String
    let duration: String
    let formattedDuration: String
    let publishedAt: String
    let thumbnailUrl: String?
}

struct SavedChannel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let colorHex: String

    init(id: String, name: String, colorHex: String? = nil) {
        self.id = id
        self.name = name
        self.colorHex = colorHex ?? SavedChannel.generateRandomColor()
    }

    // Cool dark mode palette with rich desaturated purples and complementary tones
    private static let coolPalette = [
        "#4A148C", // Deep purple
        "#6A1B9A", // Rich purple
        "#7B1FA2", // Medium purple
        "#8E24AA", // Light purple
        "#9C27B0", // Bright purple
        "#BA68C8", // Pale purple
        "#CE93D8", // Very pale purple
        "#E1BEE7", // Light lavender
        "#2E3440", // Dark slate blue
        "#3B4252", // Dark gray-blue
        "#434C5E", // Medium gray-blue
        "#4C566A", // Light gray-blue
        "#88C0D0", // Pale blue
        "#81A1C1", // Soft blue
        "#5E81AC", // Medium blue
        "#88C0D0", // Ice blue
        "#A3BE8C", // Sage green
        "#8FBCBB", // Pale teal
        "#D08770", // Soft coral
        "#EBCB8B", // Warm yellow
        "#BF616A", // Muted red
        "#B48EAD", // Dusty rose
        "#5E81AC", // Cool blue
        "#A3BE8C", // Forest green
        "#D08770", // Terracotta
        "#EBCB8B", // Honey
        "#BF616A", // Rose pink
        "#B48EAD", // Mauve
        "#4C566A", // Steel blue
    ]

    static func generateRandomColor() -> String {
        return coolPalette.randomElement() ?? "#2D3748"
    }
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
    @Published var isSearchingChannel = false
    @Published var message: String?
    @Published var messageType: MessageType = .success
    @Published var savedChannels: [SavedChannel] = []
    @Published var showChannelSavePrompt = false
    @Published var channelToSave: (id: String, name: String)?
    @Published var showEditDialog = false
    @Published var channelToEdit: SavedChannel?
    @Published var editChannelName = ""
    @Published var editChannelColor = ""
    @Published var currentChannelTitle = ""

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var scrollCallback: (() -> Void)?
    private let savedChannelsKey = "savedChannels"

    init() {
        loadSavedChannels()
    }

    // MARK: - Computed Properties
    func canFetchVideos(apiKey: String) -> Bool {
        !apiKey.isEmpty && !channelId.isEmpty
    }



    var minDurationMinutes: Double? {
        guard !minDurationText.isEmpty else { return nil }
        return Double(minDurationText)
    }

    // MARK: - Public Methods
    func setScrollCallback(_ callback: @escaping () -> Void) {
        // Store the callback in a way that can be called later
        // We'll use a simple property for this
        scrollCallback = callback
    }

    func searchChannel(config: Config) async {
        guard !channelName.isEmpty else {
            await MainActor.run {
                showMessage("Please enter a channel name", type: .error)
            }
            return
        }

        await MainActor.run {
            isSearchingChannel = true
        }
        defer {
            Task { @MainActor in
                isSearchingChannel = false
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
                    channelToSave = (id: firstChannel.id.channelId, name: firstChannel.snippet.title)
                    currentChannelTitle = firstChannel.snippet.title
                    showChannelSavePrompt = true
                    config.showChannelIdInput = true // Auto-enable Channel ID input
                    showMessage("Found channel: \(firstChannel.snippet.title)")

                    // Keep the plus button visible - no auto-dismiss
                } else {
                    showMessage("No channel found with that name", type: .error)
                }
            }
        } catch {
            await MainActor.run {
                if error.localizedDescription.contains("missing") || error.localizedDescription.contains("invalid") {
                    showMessage("Please check your API key - it might be incorrect or expired", type: .info)
                } else if error.localizedDescription.contains("quota") {
                    showMessage("YouTube API quota exceeded - try again later", type: .info)
                } else {
                    showMessage("Unable to find channel - please check the channel name", type: .info)
                }
            }
        }
    }

    func fetchVideos(config: Config) async {
        guard canFetchVideos(apiKey: config.apiKey) else {
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
                    let totalSeconds = parseDuration(item.contentDetails.duration)
                    return YouTubeVideo(
                        id: item.id,
                        title: item.snippet.title,
                        description: item.snippet.description,
                        duration: item.contentDetails.duration,
                        formattedDuration: formatDuration(totalSeconds),
                        publishedAt: item.snippet.publishedAt,
                        thumbnailUrl: item.snippet.thumbnails.medium?.url ?? item.snippet.thumbnails.default?.url
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
                // Scroll to video IDs section after successful fetch
                scrollCallback?()

                // Auto-open in YouTube if enabled in settings
                if config.autoOpenYouTubeLinks && !videoIds.isEmpty {
                    openInYouTubeApp()
                }
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

        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(iosUrl, forType: .string)
        #else
        UIPasteboard.general.string = iosUrl
        #endif
        showMessage("URL copied to clipboard")
    }

    @MainActor
    func downloadAudio() {
        #if targetEnvironment(macCatalyst) || os(macOS)
        guard !videoIds.isEmpty else {
            showMessage("No video IDs to download", type: .error)
            return
        }

        // Hardcoded path based on user environment
        let workingDirectory = "."
        
        // Construct the command string
        // Quote each video ID to be safe, though IDs are usually safe
        // Use -- to signal end of options (some video IDs start with -)
        let args = videoIds.map { "\"\($0)\"" }.joined(separator: " ")
        var command = "cd \"\(workingDirectory)\" && ./download-audio.sh"
        
        if !currentChannelTitle.isEmpty {
            command += " --channel \"\(currentChannelTitle)\""
        }
        
        command += " -- \(args)"
        
        // Copy to clipboard (always do this as backup)
        #if canImport(UIKit)
        UIPasteboard.general.string = command
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        #endif
        
        // Attempt to run via osascript Process (more reliable than NSAppleScript in Catalyst)
        var appleScriptSuccess = false
        
        // Escape for shell: backslash-escape double quotes
        let shellSafeCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
        
        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(shellSafeCommand)"
        end tell
        """
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]
        
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                appleScriptSuccess = true
                showMessage("Download started in Terminal!", type: .success)
            }
        } catch {
            // Process failed, will use fallback
        }
        
        if !appleScriptSuccess {
            showMessage("Command copied! Paste in Terminal (⌘V)", type: .success)
            
            // Fallback: Just open Terminal app
            let terminalPath = "/System/Applications/Utilities/Terminal.app"
            let terminalUrl = URL(fileURLWithPath: terminalPath)
            
            #if canImport(UIKit)
            UIApplication.shared.open(terminalUrl, options: [:]) { _ in }
            #elseif canImport(AppKit)
            NSWorkspace.shared.open(terminalUrl)
            #endif
        }
        #else
        // Download feature is not supported on physical iOS devices
        showMessage("Downloads are only supported on macOS", type: .info)
        #endif
    }

    @MainActor
    func openInYouTubeApp() {
        guard !videoIds.isEmpty else {
            showMessage("No video IDs to open", type: .error)
            return
        }

        let playlistUrl = "https://www.youtube.com/watch_videos?video_ids=\(videoIds.joined(separator: ","))"

        if let url = URL(string: playlistUrl) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url)
            #endif
            showMessage("Opened in browser")
        } else {
            showMessage("Unable to open URL", type: .error)
        }
    }

    @MainActor
    func openVideo(id: String) {
        let videoUrl = "https://www.youtube.com/watch?v=\(id)"
        if let url = URL(string: videoUrl) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url)
            #endif
        }
    }

    @MainActor
    func sharePlaylist() {
        guard !videoIds.isEmpty else {
            showMessage("No video IDs to share", type: .error)
            return
        }

        let playlistUrl = "https://www.youtube.com/watch_videos?video_ids=\(videoIds.joined(separator: ","))"

        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(playlistUrl, forType: .string)
        #else
        UIPasteboard.general.string = playlistUrl
        #endif
        showMessage("Playlist URL copied to clipboard")
    }

    // MARK: - Saved Channels Methods
    @MainActor
    func saveChannel(_ channel: SavedChannel) {
        if !savedChannels.contains(where: { $0.id == channel.id }) {
            savedChannels.append(channel)
            saveSavedChannels()
            // Removed success message
        }
    }

    @MainActor
    func saveCurrentChannel() {
        if let channelToSave = channelToSave {
            let savedChannel = SavedChannel(id: channelToSave.id, name: channelToSave.name)
            saveChannel(savedChannel)
            self.channelToSave = nil
            // Removed showChannelSavePrompt = false to prevent "Found channel" message
        }
    }

    @MainActor
    func dismissChannelSavePrompt() {
        channelToSave = nil
        showChannelSavePrompt = false
    }

    @MainActor
    func selectSavedChannel(_ channel: SavedChannel) {
        channelId = channel.id
        currentChannelTitle = channel.name
        showMessage("\(channel.name) added")
    }

    @MainActor
    func deleteSavedChannel(_ channel: SavedChannel) {
        savedChannels.removeAll { $0.id == channel.id }
        saveSavedChannels()
        // Removed success message for channel deletion
    }

    @MainActor
    func editSavedChannel(_ channel: SavedChannel) {
        channelToEdit = channel
        editChannelName = channel.name
        editChannelColor = channel.colorHex
        showEditDialog = true
    }

    @MainActor
    func saveEditedChannel() {
        guard let channelToEdit = channelToEdit, !editChannelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        if let index = savedChannels.firstIndex(where: { $0.id == channelToEdit.id }) {
            let updatedChannel = SavedChannel(id: channelToEdit.id, name: editChannelName.trimmingCharacters(in: .whitespacesAndNewlines), colorHex: editChannelColor)
            savedChannels[index] = updatedChannel
            saveSavedChannels()
            showMessage("Channel updated")
        }
        
        self.channelToEdit = nil
        editChannelName = ""
        editChannelColor = ""
        showEditDialog = false
    }

    @MainActor
    func cancelEdit() {
        channelToEdit = nil
        editChannelName = ""
        editChannelColor = ""
        showEditDialog = false
    }
    
    @MainActor
    func reorderChannel(from channel: SavedChannel, to gridLocation: CGPoint) {
        guard let currentIndex = savedChannels.firstIndex(where: { $0.id == channel.id }) else {
            return
        }

        // Convert grid coordinates to array index more accurately
        let column = Int(round(gridLocation.x)) // Round to nearest column (0 or 1)
        let row = Int(round(gridLocation.y)) // Round to nearest row

        // Calculate target index based on grid position
        let targetIndex = row * 2 + column

        // Ensure target index is within valid bounds
        let clampedTargetIndex = max(0, min(targetIndex, savedChannels.count))

        // Don't reorder if the target is the same as current or adjacent in a way that doesn't change position
        if clampedTargetIndex == currentIndex {
            return
        }

        // Remove the channel from its current position
        let movedChannel = savedChannels.remove(at: currentIndex)

        // Insert at the new position
        savedChannels.insert(movedChannel, at: clampedTargetIndex)

        // Save the updated order
        saveSavedChannels()
    }

    private func loadSavedChannels() {
        if let data = UserDefaults.standard.data(forKey: savedChannelsKey) {
            do {
                savedChannels = try JSONDecoder().decode([SavedChannel].self, from: data)
            } catch {
                print("Error loading saved channels: \(error)")
                savedChannels = []
            }
        }
    }

    private func saveSavedChannels() {
        do {
            let data = try JSONEncoder().encode(savedChannels)
            UserDefaults.standard.set(data, forKey: savedChannelsKey)
        } catch {
            print("Error saving saved channels: \(error)")
        }
    }

    // MARK: - Private Methods
    @MainActor
    private func showMessage(_ text: String, type: MessageType = .success) {
        message = text
        messageType = type

        // Clear message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            Task { @MainActor in
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

    private func formatDuration(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
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
    let thumbnails: YouTubeThumbnails
}

struct YouTubeThumbnails: Codable {
    let `default`: YouTubeThumbnail?
    let medium: YouTubeThumbnail?
}

struct YouTubeThumbnail: Codable {
    let url: String
}

struct YouTubeContentDetails: Codable {
    let duration: String
}
