# YouTube Playlist Creator

A modern, native iOS/macOS application for creating YouTube playlists from channel videos. Extract video IDs from any YouTube channel and generate playlists with customizable filtering options.

![YouTube Playlist Creator](https://img.shields.io/badge/Platform-iOS%20%2F%20macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![YouTube Data API](https://img.shields.io/badge/YouTube%20Data%20API-v3-red)

## Features

### Smart Channel Discovery
- **Channel Search**: Find YouTube channels by name
- **Direct Channel ID**: Input channel IDs directly
- **Real-time Validation**: Instant feedback on channel availability

### Advanced Video Filtering
- **Sort Options**: Date, Duration, Year, Random, Default
- **Content Types**: Include/exclude YouTube Shorts
- **Keyword Filtering**: Filter by title or description keywords
- **Duration Limits**: Set minimum video duration
- **Video Count**: Configurable limit (10-100 videos)

### Beautiful Dark UI
- **Glassmorphism Design**: Modern translucent effects
- **Dark Theme**: Easy on the eyes with consistent styling
- **Responsive Layout**: Optimized for iOS and macOS
- **Intuitive Navigation**: Clean, user-friendly interface

### Native Performance
- **SwiftUI**: Modern declarative UI framework
- **Native Controls**: Platform-optimized components
- **Smooth Animations**: Fluid transitions and interactions
- **Background Processing**: Non-blocking API calls

## Installation

### Prerequisites
- **macOS**: 11.0+ or **iOS**: 14.6+
- **Xcode**: 13.0+ (for development)
- **YouTube Data API v3** key (see setup below)

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/saihgupr/YouTubePlaylistCreator.git
   cd YouTubePlaylistCreator
   ```

2. **Open in Xcode**
   ```bash
   open YouTubePlaylistCreator.xcodeproj
   ```

3. **Configure API Key** (see YouTube API Setup below)

4. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

## YouTube API Setup

### Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click **"Create Project"** or select an existing project
3. Give your project a name (e.g., "YouTube Playlist Creator")

### Step 2: Enable YouTube Data API v3

1. In the Cloud Console, go to **"APIs & Services"** > **"Library"**
2. Search for **"YouTube Data API v3"**
3. Click on it and then click **"Enable"**

### Step 3: Create API Credentials

1. Go to **"APIs & Services"** > **"Credentials"**
2. Click **"Create Credentials"** > **"API key"**
3. Copy the generated API key

### Step 4: Configure the App

1. Open the app and go to **Settings** (gear icon)
2. Paste your API key in the **"YouTube API"** section
3. The app will validate the key automatically

### Step 5: Set API Quotas (Optional)

The YouTube Data API has daily quotas. For the YouTube Playlist Creator:

- **Cost per request**: ~1 unit
- **Daily quota needed**: ~100-500 units (depending on usage)
- **Free tier**: 10,000 units per day should be sufficient

To increase your quota:
1. Go to **"APIs & Services"** > **"Quotas"**
2. Find **"YouTube Data API v3"**
3. Request a quota increase if needed

## Usage Guide

### Basic Workflow

1. **Launch the App**
   - Open YouTube Playlist Creator on your device

2. **Configure Settings**
   - Tap the gear icon to open settings
   - Enter your YouTube API key
   - Set your preferred video limits and filters

3. **Find a Channel**
   - Enter a YouTube channel name in the search field
   - Or paste a channel ID directly
   - Click **"Search"** to find the channel

4. **Customize Filters**
   - **Sort Order**: Choose how to order videos
   - **Content Types**: Include/exclude Shorts
   - **Keyword Filter**: Filter by specific words
   - **Minimum Duration**: Set duration limits
   - **Max Videos**: Limit the number of videos (10-100)

5. **Generate Playlist**
   - Click **"Get Video IDs"** to fetch videos
   - Review the generated video IDs
   - Copy the IDs or open directly in YouTube

### Advanced Features

#### Sorting Options
- **Date**: Newest videos first
- **Duration**: Longest to shortest
- **Year**: Group by publication year
- **Random**: Shuffle the order
- **Default**: YouTube's default order

#### Content Filtering
- **YouTube Shorts**: Toggle on/off
- **Keyword Matching**: Case-insensitive search in titles/descriptions
- **Duration Filtering**: Exclude videos shorter than specified time

## Architecture

### Tech Stack
- **Frontend**: SwiftUI (iOS 14.6+, macOS 11.0+)
- **API**: YouTube Data API v3
- **State Management**: Combine framework
- **Networking**: URLSession with JSONDecoder
- **Persistence**: AppStorage for user preferences

### Project Structure
```
YouTubePlaylistCreator/
├── YouTubePlaylistCreatorApp.swift     # App entry point
├── ContentView.swift                   # Main interface
├── SettingsView.swift                  # Settings screen
├── YouTubeViewModel.swift             # Business logic & API calls
├── Config.swift                       # App configuration
└── Assets.xcassets/                   # App icons & colors
```

### Key Components

#### YouTubeViewModel
- Manages YouTube API interactions
- Handles video filtering and sorting
- Processes API responses and errors
- Manages loading states and UI updates

#### Config
- Stores user preferences (API key, video limits)
- Persistent storage using @AppStorage
- Environment object for global access

## Development

### Requirements
- **Xcode**: 13.0+
- **Swift**: 5.0+
- **iOS Deployment Target**: 14.6+
- **macOS Deployment Target**: 11.0+

### Building from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/saihgupr/YouTubePlaylistCreator.git
   ```

2. **Open in Xcode**
   ```bash
   cd YouTubePlaylistCreator
   open YouTubePlaylistCreator.xcodeproj
   ```

3. **Configure Signing**
   - Go to project settings > Signing & Capabilities
   - Select your development team
   - Or disable code signing for development builds

4. **Add API Key**
   - Create a `Config.xcconfig` file or
   - Set the API key directly in the app's Settings

### Code Style
- **SwiftLint**: Recommended for consistent code style
- **SwiftFormat**: For automatic code formatting
- **Documentation**: All public APIs should be documented

## API Usage & Limits

### YouTube Data API v3 Quotas
- **Search Request**: 100 units
- **Channel Info**: 1 unit
- **Playlist Items**: 1 unit per 50 videos

### Cost Estimation
For typical usage (fetching 50 videos from 1 channel):
- **API Calls**: ~3-5 requests
- **Total Cost**: ~300 units
- **Free Tier**: 10,000 units/day (sufficient for most users)

### Rate Limiting
- **Per User**: No specific limits beyond quotas
- **Per API Key**: Subject to Google Cloud quotas
- **Caching**: Implement local caching to reduce API calls

## Troubleshooting

### Common Issues

#### "Invalid API Key" Error
- Verify your API key is correct
- Check that YouTube Data API v3 is enabled
- Ensure your API key has the correct permissions

#### "Channel Not Found" Error
- Double-check the channel name spelling
- Try using the channel ID instead
- Verify the channel exists and is public

#### App Won't Load Videos
- Check your internet connection
- Verify API quotas haven't been exceeded
- Try reducing the video limit in settings

### Debug Mode
Enable debug logging in Xcode:
1. Go to **Product** > **Scheme** > **Edit Scheme**
2. Select **Run** > **Arguments** tab
3. Add `-com.apple.CoreData.ConcurrencyDebug 1` to environment variables

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### How to Contribute
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Swift naming conventions
- Add unit tests for new features
- Update documentation as needed
- Test on both iOS and macOS targets

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/saihgupr/YouTubePlaylistCreator/issues) page
2. Create a new issue with detailed information
3. Include your device/OS version and steps to reproduce

## Acknowledgments

- **YouTube Data API v3** for providing the backend functionality
- **Google Cloud Platform** for hosting the API
- **SwiftUI** for the modern UI framework
- **The Swift Community** for excellent documentation and resources

---

**Made with love for YouTube creators and viewers**

*Extract video IDs, create playlists, and enhance your YouTube experience with this powerful native app.*
