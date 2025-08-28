# YouTube Playlist Creator

A native iOS/macOS app for extracting YouTube video IDs from channels and creating custom playlists with advanced filtering options.

![YouTube Playlist Creator](https://img.shields.io/badge/Platform-iOS%20%2F%20macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)

## Features

- **Channel Discovery**: Search by channel name or use channel IDs
- **Video Filtering**: Sort by date, duration, year, or random order
- **Content Control**: Include/exclude YouTube Shorts
- **Keyword Filtering**: Filter videos by title/description keywords
- **Duration Limits**: Set minimum video duration
- **Video Count**: Configurable limit (10-100 videos)
- **Dark UI**: Modern glassmorphism design

## Requirements

- **iOS**: 14.6+ or **macOS**: 11.0+
- **YouTube Data API v3** key (free from Google)

## YouTube API Setup

### 1. Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one

### 2. Enable YouTube Data API v3
1. Navigate to **APIs & Services** > **Library**
2. Search for **YouTube Data API v3**
3. Click **Enable**

### 3. Get API Key
1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **API key**
3. Copy the generated key

### 4. Configure App
1. Open the app and go to **Settings**
2. Paste your API key in the **YouTube API** section

## Usage

1. **Enter Channel**: Type channel name or paste channel ID
2. **Search**: Click search button to find the channel
3. **Customize**: Set filters (sort order, duration, keywords, etc.)
4. **Generate**: Click "Get Video IDs" to fetch videos
5. **Export**: Copy video IDs or open in YouTube

## Installation

```bash
git clone https://github.com/saihgupr/YouTubePlaylistCreator.git
cd YouTubePlaylistCreator
open YouTubePlaylistCreator.xcodeproj
```

Build and run in Xcode (requires API key in Settings).

## Troubleshooting

**"Invalid API Key"**
- Verify API key is correct and YouTube Data API v3 is enabled

**"Channel Not Found"**
- Double-check spelling or try using channel ID instead

**"No Videos Found"**
- Check internet connection and API quotas
- Try reducing video count limit

## Tech Stack

- **SwiftUI** - Modern UI framework
- **YouTube Data API v3** - Video data source
- **Combine** - Reactive programming
- **URLSession** - Networking

## License

MIT License - see [LICENSE](LICENSE) file for details.
