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
                // Header - Match web version exactly
                VStack(spacing: 8) {
                    #if targetEnvironment(macCatalyst)
                    // Add extra top padding for Mac Catalyst
                    Spacer()
                        .frame(height: 5)
                    #endif
                    
                    // Settings button in top right
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
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    // Title and subtitle - match web version
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Text("📺")
                                .font(.system(size: 32))
                            Text("YouTube Tool")
                                .font(.system(size: horizontalSizeClass == .regular ? 32 : 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Extract video IDs from any YouTube channel")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#8E8E93"))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 2)

                // Main content - match web version spacing
                VStack(spacing: 20) {
                    // Add padding below subtitle
                    Spacer()
                        .frame(height: 40)

                    // Message Area
                    if let message = viewModel.message, !config.apiKey.isEmpty {
                        MessageView(message: message, type: viewModel.messageType)
                            .padding(.horizontal, 24)
                    }
                    if config.apiKey.isEmpty && viewModel.message == nil {
                        MessageView(message: "Please add your YouTube API key in Settings to get started.", type: .info)
                            .padding(.horizontal, 24)
                    }

                    // Channel Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Channel Name:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("Enter YouTube Channel Name", text: $viewModel.channelName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#000000").opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .disableAutocorrection(true)
                            .disabled(viewModel.isLoading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)

                    // Search Channel Button
                    Button(action: {
                        Task {
                            await viewModel.searchChannel()
                        }
                    }) {
                        HStack {
                            Text("🔍 Search Channel")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#000000").opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.channelName.isEmpty || viewModel.isLoading)
                    .padding(.horizontal, 24)

                    // Channel ID Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Channel ID:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("Enter the YouTube Channel ID", text: $viewModel.channelId)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#000000").opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .disableAutocorrection(true)
                            .disabled(viewModel.isLoading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)

                    // Video Settings Section Title
                    Text("Video Settings")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)

                    // Order Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Order:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        CustomDropdownView(selectedOrder: $viewModel.selectedOrder)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#000000").opacity(0.3))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 24)

                    // Keyword Filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keyword Filter:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("Filter by keyword in title/description", text: $viewModel.keywordFilter)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#000000").opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .disableAutocorrection(true)
                            .disabled(viewModel.isLoading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)

                    // Minimum Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Duration (minutes):")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("e.g., 5 for 5 minutes", text: $viewModel.minDurationText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#000000").opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .disableAutocorrection(true)
                            .disabled(viewModel.isLoading)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)

                    // YouTube Shorts Toggle - match web version exactly
                    HStack {
                        Text("YouTube Shorts")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#8E8E93"))
                        Spacer()
                        Toggle("", isOn: $viewModel.includeShorts)
                            .labelsHidden()
                            .disabled(viewModel.isLoading)
                            .toggleStyle(CustomToggleStyle())
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    // Get Videos Button
                    Button(action: {
                        Task {
                            await viewModel.fetchVideos()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "play.circle")
                                Text("Get Video IDs")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isLoading ? Color(hex: "#30D158") : (viewModel.canFetchVideos ? Color(hex: "#007AFF") : Color(hex: "#2C2C2E")))
                        .foregroundColor(viewModel.canFetchVideos ? .white : Color(hex: "#8E8E93"))
                        .cornerRadius(16)
                    }
                    .disabled(!viewModel.canFetchVideos || viewModel.isLoading)
                    .padding(.horizontal, 24)

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
                        .padding(.horizontal, 24)
                    }

                    // Video IDs Display - match web version
                    if !viewModel.videoIds.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Video IDs:")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)

                            ScrollView(.horizontal, showsIndicators: true) {
                                Text(viewModel.videoIds.joined(separator: ", "))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color(hex: "#000000").opacity(0.3))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .frame(height: 150)
                        }
                        .padding(.horizontal, 24)
                        .id("videoIdsSection")
                    }

                    // Loading indicator - match web version
                    if viewModel.isLoading {
                        VStack(spacing: 8) {
                            Text("🔄 Fetching videos...")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#8E8E93"))
                            Text("Please wait while we retrieve the channel data")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#8E8E93"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 25)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .overlay(
                            Rectangle()
                                .frame(width: 3)
                                .foregroundColor(Color(hex: "#007AFF"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cornerRadius(16)
                        )
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color(hex: "#1C1C1E"))
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

// Custom Toggle Style to match web version
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .fill(configuration.isOn ? Color(hex: "#007AFF") : Color.white.opacity(0.2))
                .frame(width: 60, height: 32)
                .cornerRadius(32)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 24, height: 24)
                        .offset(x: configuration.isOn ? 14 : -14)
                        .animation(.easeInOut(duration: 0.4), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

struct MessageView: View {
    let message: String
    let type: MessageType

    private var backgroundColor: Color {
        switch type {
            case .success: return Color(hex: "#30D158").opacity(0.1)
            case .error: return Color(hex: "#FF453A").opacity(0.1)
            case .info: return Color(hex: "#007AFF").opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        switch type {
            case .success: return Color(hex: "#30D158")
            case .error: return Color(hex: "#FF453A")
            case .info: return Color(hex: "#007AFF")
        }
    }

    private var strokeColor: Color {
        switch type {
            case .success: return Color(hex: "#30D158").opacity(0.2)
            case .error: return Color(hex: "#FF453A").opacity(0.2)
            case .info: return Color(hex: "#007AFF").opacity(0.2)
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
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
        }
        .padding(12)
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
