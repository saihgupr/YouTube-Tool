# <img src="https://i.imgur.com/ceUFUjO.png" alt="YouTube Playlist Creator Icon" width="4%" height="4%" style="vertical-align: middle; margin-bottom: 2px;"> YouTube Playlist Creator

A native iOS/macOS app for extracting YouTube video IDs from channels and creating custom playlists with advanced filtering options.

## Screenshots

<div align="center">
  <img src="https://i.imgur.com/4hWS7G3.png" width="250" alt="Video Results">
  <img src="https://i.imgur.com/CpTwoZs.png" width="250" alt="Dropdown Menu">
  <img src="https://i.imgur.com/qB0iHOA.png" width="250" alt="Mac Catalyst">
</div>

<div align="center">
  <img src="https://i.imgur.com/TrUcBqT.png" width="300" alt="Main Interface">
  <img src="https://i.imgur.com/dVGvs5t.png" width="400" alt="Settings View">
</div>

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
3. Note your **Project ID** for later use

### 2. Enable YouTube Data API v3
1. Navigate to **APIs & Services** > **Library**
2. Search for **YouTube Data API v3**
3. Click **Enable**
4. Wait for the API to be fully enabled (may take a few minutes)

### 3. Create API Key
1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **API key**
3. Copy the generated API key
4. **Important**: Click on the API key to configure it

### 4. Configure API Key Permissions
1. In the API key settings, under **API restrictions**:
   - Select **Restrict key**
   - Choose **YouTube Data API v3** from the dropdown
2. Under **Application restrictions** (optional but recommended):
   - Select **iOS Apps** or **macOS Apps** depending on your platform
   - Add your app's bundle identifier
3. Click **Save**

### 5. Set Up Billing (Required)
1. Go to **Billing** in the Google Cloud Console
2. Link a billing account to your project
3. **Note**: YouTube Data API v3 has a free tier of 10,000 units per day
4. Each API call typically costs 1-5 units depending on the operation

### 6. Configure App
1. Open the app and go to **Settings**
2. Paste your API key in the **YouTube API** section
3. The key will be securely stored in your device's keychain

## API Permissions Required

The YouTube Data API v3 requires the following permissions for this app to function:

- **youtube.readonly** - Read access to YouTube data
- **youtube.channel.readonly** - Access to channel information
- **youtube.playlist.readonly** - Access to playlist data
- **youtube.video.readonly** - Access to video metadata

These permissions are automatically granted when you enable the YouTube Data API v3.

## API Quotas & Limits

- **Free Tier**: 10,000 units per day
- **Search API**: 100 units per request
- **Channels API**: 1 unit per request
- **Playlist Items API**: 1 unit per request
- **Videos API**: 1 unit per request

**Typical Usage**: Fetching 50 videos from a channel uses approximately 150-200 API units.

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

**"Please check your API key - it might be incorrect or expired"**
- Verify API key is correct and YouTube Data API v3 is enabled
- Check that billing is set up for your Google Cloud project
- Ensure API key has proper restrictions configured

**"YouTube API quota exceeded - try again later"**
- You've reached the daily quota limit (10,000 units)
- Wait until tomorrow or upgrade to a paid plan
- Check your API usage in Google Cloud Console

**"Unable to find channel - please check the channel name"**
- Double-check spelling or try using channel ID instead
- Ensure the channel exists and is public
- Try searching for the channel on YouTube first

**"No Videos Found"**
- Check internet connection and API quotas
- Verify the channel has uploaded videos
- Try different search terms or channel ID

**"Could not find uploads playlist"**
- The channel may be private or have no public videos
- Try a different channel or check channel permissions

## Tech Stack

- **SwiftUI** - Modern UI framework
- **YouTube Data API v3** - Video data source
- **Combine** - Reactive programming
- **URLSession** - Networking

## License

MIT License - see [LICENSE](LICENSE) file for details.
