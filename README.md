# YouTube Tool <img src="https://i.imgur.com/m5eS9OJ.png" width="5%" align="right" />

A native iOS and macOS app for extracting YouTube video IDs from channels and creating custom playlists with advanced filtering options.

### iPhone
<div align="center">
  <img src="https://i.imgur.com/JPxpDNE.png" width="250" alt="Video Results">
  <img src="https://i.imgur.com/WGeepze.png" width="250" alt="Dropdown Menu">
  <img src="https://i.imgur.com/VVmEDxW.png" width="250" alt="Mac Catalyst">
</div>

### iPad & Mac
<div align="center">
  <img src="https://i.imgur.com/QKqtt7w.png" width="400" alt="Main Interface">
  <img src="https://i.imgur.com/J0jobat.jpeg" width="400" alt="Settings View">
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

### 5. Configure App
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

### Option 1: Download from Releases
- iOS: Download the `.ipa` from [Releases](https://github.com/DiggingForDinos/YouTubePlaylistCreator/releases) and sideload to your device.
- macOS: Download the `.app` (or `.dmg`) from [Releases](https://github.com/DiggingForDinos/YouTubePlaylistCreator/releases) and drag to Applications.

### Option 2: Build from Source
```bash
git clone https://github.com/DiggingForDinos/YouTubePlaylistCreator.git
cd YouTubePlaylistCreator
open YouTubePlaylistCreator.xcodeproj
```

Then build and run in Xcode. You’ll need to add your API key in the app’s Settings.

## Tech Stack

- **SwiftUI** - Modern UI framework
- **YouTube Data API v3** - Video data source
- **Combine** - Reactive programming
- **URLSession** - Networking

## Audio Download Feature (macOS)

Download audio from YouTube videos using the included `download-audio.sh` script.

### Requirements

Install the required dependencies via Homebrew:

```bash
brew install yt-dlp ffmpeg
```

### Usage

1. Use the app to find and filter videos from a channel.
2. Click **"Download Audio"** - This will copy the download command to your clipboard and open Terminal.
3. **Important**: If the download doesn't start automatically, simply **paste (⌘V)** in the Terminal window and press Enter.
4. Audio files are saved to `~/Music/YouTube` and are automatically organized into subfolders by channel name.

**Manual usage from Terminal:**

```bash
# Download specific videos
./download-audio.sh dQw4w9WgXcQ oHg5SJYRHA0

# Download and organize into a channel folder
./download-audio.sh --channel "Favorite Channel" dQw4w9WgXcQ

# Download from playlist URL
./download-audio.sh --url "https://www.youtube.com/watch_videos?video_ids=id1,id2"

# Read video IDs from a file
./download-audio.sh --file video_ids.txt
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--channel, -c` | Organize files into a channel-named subfolder | - |
| `--output, -o DIR` | Base output directory | `~/Music/YouTube` |
| `--format, -F FMT` | Audio format: mp3, m4a, opus, wav | mp3 |
| `--quality, -q NUM` | MP3 quality: 0=best, 9=worst | 0 |
| `--help, -h` | Show help message | - |

### Examples

```bash
# Download as M4A to custom folder
./download-audio.sh -o ~/Downloads/Music -F m4a dQw4w9WgXcQ

```bash
# Download from playlist URL
./download-audio.sh --url "https://www.youtube.com/watch_videos?video_ids=abc,def,ghi"
```

---

**Note**: This tool is provided for educational and personal archival purposes. Users are responsible for ensuring their use of this software complies with YouTube's Terms of Service and applicable copyright laws.

---

## Support & Feedback

If you encounter any bugs or have feature requests, please feel free to open an issue on the [GitHub Issues](https://github.com/DiggingForDinos/YouTubePlaylistCreator/issues) page.

If you enjoy using this tool, please consider giving the repository a star ⭐️!
