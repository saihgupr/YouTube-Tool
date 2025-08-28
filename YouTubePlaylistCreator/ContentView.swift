//  ContentView.swift
//  YouTubePlaylistCreator
//
//  Created by Chris Lapointe
//  Main view replicating the web app functionality
//

import SwiftUI



// Hex color extension for custom colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Modifiers for iPad-specific safe area handling
struct SafeAreaTopIgnorer: ViewModifier {
    func body(content: Content) -> some View {
        content.ignoresSafeArea(.container, edges: .top)
    }
}

struct EmptyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

struct ContentView: View {
    @EnvironmentObject private var config: Config
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: Ultra-minimal layout - no containers at all
                ScrollViewReader { scrollProxy in
                    YouTubePlaylistCreatorView(scrollProxy: scrollProxy)
                        .environmentObject(config)
                        .background(Color(hex: "#000000"))
                        .edgesIgnoringSafeArea(.all)
                }
            } else {
                // iPhone: Match iPad layout without NavigationView
                ScrollViewReader { scrollProxy in
                    YouTubePlaylistCreatorView(scrollProxy: scrollProxy)
                        .environmentObject(config)
                        .background(Color(hex: "#000000"))
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
}

struct YouTubePlaylistCreatorView: View {
    @EnvironmentObject private var config: Config
    let scrollProxy: ScrollViewProxy?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var viewModel: YouTubeViewModel
    @State private var showSettings = false // For iPad sheet

    init(scrollProxy: ScrollViewProxy?) {
        self.scrollProxy = scrollProxy
        _viewModel = StateObject(wrappedValue: YouTubeViewModel(config: Config()))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                        // Header - Minimal for iPad, full for iPhone
                        VStack(spacing: horizontalSizeClass == .regular ? 8 : 16) {
                            #if targetEnvironment(macCatalyst)
                            // Add extra top padding for Mac Catalyst
                            Spacer()
                                .frame(height: 5)
                            #endif
                            if horizontalSizeClass == .regular {
                                // iPad: Show title and settings button in header
                                VStack(alignment: .center, spacing: 8) {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            showSettings = true
                                        }) {
                                            Image(systemName: "gear")
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    VStack(spacing: 4) {
                                        Text("YouTube Playlist Creator")
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                        Text("Extract video IDs from YouTube channels")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: "#8E8E93"))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            } else {
                                // iPhone: Match iPad layout with settings button in top right
                                VStack(alignment: .center, spacing: 8) {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            showSettings = true
                                        }) {
                                            Image(systemName: "gear")
                                                .font(.system(size: 18))
                                                .foregroundColor(.white)
                                        }
                                    }

                                    VStack(spacing: 4) {
                                        Text("YouTube Playlist Creator")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                        Text("Extract video IDs from YouTube channels")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color(hex: "#8E8E93"))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 36) // Same padding for both iPhone and iPad
                        .padding(.bottom, 24)

                        // Main content
                        VStack(spacing: 24) {
                            // Message Area
                            if let message = viewModel.message, !config.apiKey.isEmpty {
                                MessageView(message: message, type: viewModel.messageType)
                            }
                            if config.apiKey.isEmpty && viewModel.message == nil {
                                MessageView(message: "Please add your YouTube API key in Settings to get started.", type: .info)
                            }

                            // Combined Channel Search & Video Settings Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Channel & Video Settings")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)

                                VStack(spacing: 16) {
                                    // Channel name search
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Channel Name")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "#8E8E93"))

                                        TextField("Enter YouTube Channel Name", text: $viewModel.channelName)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(16)
                                            .background(Color(hex: "#1C1C1E"))
                                            .cornerRadius(12)
                                            .foregroundColor(.white)
                                            .disableAutocorrection(true)
                                            .disabled(viewModel.isLoading)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }

                                    // Search Button - Moved below channel input
                                    Button(action: {
                                        Task {
                                            await viewModel.searchChannel()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "magnifyingglass")
                                            Text("Search")
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "#007AFF"))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .disabled(viewModel.channelName.isEmpty || viewModel.isLoading)

                                    // Channel ID
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Channel ID")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "#8E8E93"))

                                        TextField("Enter the YouTube Channel ID", text: $viewModel.channelId)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(16)
                                            .background(Color(hex: "#1C1C1E"))
                                            .cornerRadius(12)
                                            .foregroundColor(.white)
                                            .disableAutocorrection(true)
                                            .disabled(viewModel.isLoading)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }

                                    // Order Picker
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Sort Order")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "#8E8E93"))

                                        CustomDropdownView(selectedOrder: $viewModel.selectedOrder)
                                            .padding(16)
                                            .background(Color(hex: "#2C2C2E"))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        .disabled(viewModel.isLoading)
                                    }

                                    // Keyword Filter
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Keyword Filter")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "#8E8E93"))

                                        TextField("Filter by keyword in title/description", text: $viewModel.keywordFilter)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(16)
                                            .background(Color(hex: "#1C1C1E"))
                                            .cornerRadius(12)
                                            .foregroundColor(.white)
                                            .disableAutocorrection(true)
                                            .disabled(viewModel.isLoading)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }

                                    // Minimum Duration
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Minimum Duration (minutes)")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "#8E8E93"))

                                        TextField("e.g., 5", text: $viewModel.minDurationText)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(16)
                                            .background(Color(hex: "#1C1C1E"))
                                            .cornerRadius(12)
                                            .foregroundColor(.white)
                                            .keyboardType(.decimalPad)
                                            .disableAutocorrection(true)
                                            .disabled(viewModel.isLoading)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    }

                                    // YouTube Shorts Toggle
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Content Types")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "#8E8E93"))

                                        HStack {
                                            Text("Include YouTube Shorts")
                                                .foregroundColor(.white)
                                            Spacer()
                                            Toggle("", isOn: $viewModel.includeShorts)
                                                .labelsHidden()
                                                .disabled(viewModel.isLoading)
                                        }
                                        .padding(16)
                                        .background(Color(hex: "#2C2C2E"))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(hex: "#1C1C1E"))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

                            // Action Buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await viewModel.fetchVideos()
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Image(systemName: "play.circle")
                                        }
                                        Text(viewModel.isLoading ? "Fetching Videos..." : "Get Video IDs")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(viewModel.canFetchVideos ? Color(hex: "#30D158") : Color(hex: "#2C2C2E"))
                                    .foregroundColor(viewModel.canFetchVideos ? .white : Color(hex: "#8E8E93"))
                                    .cornerRadius(16)
                                }
                                .disabled(!viewModel.canFetchVideos || viewModel.isLoading)

                                // Export Buttons - Only show when videos are available
                                if !viewModel.videoIds.isEmpty {
                                    Button(action: {
                                        viewModel.openInYouTubeApp()
                                    }) {
                                        HStack {
                                            Image(systemName: "play.tv")
                                            Text("Open in YouTube")
                                                .font(.system(size: 17, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color(hex: "#2C2C2E"))
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                }
                            }

                            // Video IDs Display
                            if !viewModel.videoIds.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Video IDs (\(viewModel.videoIds.count) videos)")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)

                                    ScrollView(.horizontal, showsIndicators: true) {
                                        Text(viewModel.videoIds.joined(separator: ", "))
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundColor(.white)
                                            .padding(16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .background(Color(hex: "#1C1C1E"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .frame(height: 80)
                                }
                                .id("videoIdsSection")
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
                                .background(Color(hex: "#000000"))
                .onAppear {
                    // Set scroll callback for auto-scroll after video fetch
                    viewModel.setScrollCallback { [scrollProxy] in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let scrollProxy = scrollProxy {
                                withAnimation {
                                    scrollProxy.scrollTo("videoIdsSection", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
        .sheet(isPresented: $showSettings) {
            SettingsView(dismissAction: {
                showSettings = false
            })
            .environmentObject(config)
        }
    }
}

struct MessageView: View {
    let message: String
    let type: MessageType

    private var backgroundColor: Color {
        switch type {
            case .success: return Color.green.opacity(0.1)
            case .error: return Color.red.opacity(0.1)
            case .info: return Color.blue.opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        switch type {
            case .success: return Color(.systemGreen)
            case .error: return Color(.systemRed)
            case .info: return Color(.systemBlue)
        }
    }

    private var strokeColor: Color {
        switch type {
            case .success: return Color.green.opacity(0.2)
            case .error: return Color.red.opacity(0.2)
            case .info: return Color.blue.opacity(0.2)
        }
    }

    private var iconName: String {
        switch type {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(foregroundColor)
                Text(message)
                    .foregroundColor(foregroundColor)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
            }
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(strokeColor, lineWidth: 1)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(DefaultButtonStyle())
        }
    }
}

// MARK: - Custom Dropdown for VideoOrder
struct CustomDropdownView: View {
    @Binding var selectedOrder: VideoOrder
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main button - entire area is clickable
            Button(action: {
                #if targetEnvironment(macCatalyst)
                // For Mac Catalyst, use immediate toggle without animation
                isExpanded.toggle()
                #else
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
                #endif
            }) {
                HStack {
                    Text(selectedOrder.displayName)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color(hex: "#8E8E93"))
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Dropdown options
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(VideoOrder.sortedCases, id: \.self) { order in
                        Button(action: {
                            selectedOrder = order
                            #if targetEnvironment(macCatalyst)
                            // For Mac Catalyst, use immediate close without animation
                            isExpanded = false
                            #else
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                            #endif
                        }) {
                            HStack {
                                Text(order.displayName)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                Spacer()
                                if order == selectedOrder {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#007AFF"))
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if order != VideoOrder.sortedCases.last {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(hex: "#1C1C1E"))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.top, 8)
                #if !targetEnvironment(macCatalyst)
                .transition(.opacity.combined(with: .move(edge: .top)))
                #endif
            }
        }
    }
}
