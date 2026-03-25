import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var config: Config
    @StateObject private var viewModel = YouTubeViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showSettings = false
    @State private var dragOffset: CGSize = .zero
    @State private var draggedItem: SavedChannel?
    @State private var anyDeleteModeActive = false
    @State private var isScrollTargetProgrammatic = false
    
    // Grid animation namespace
    @Namespace private var animation
    
    // Grid layout
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // ScrollReader proxy
    @State private var scrollProxy: ScrollViewProxy?
    
    private func convertToGridCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        let gridFrame = geometry.frame(in: .local)
        let gridWidth = gridFrame.width
        let itemWidth = (gridWidth - 12) / 2 // 12 is spacing
        let itemHeight: CGFloat = 72
        
        let gridBounds = CGRect(x: 0, y: 0, width: gridWidth, height: CGFloat((viewModel.savedChannels.count + 1) / 2) * itemHeight)
        
        // Convert the drag location to coordinates relative to the grid
        let relativeX = location.x - gridBounds.minX
        let relativeY = location.y - gridBounds.minY

        // Calculate grid position
        let gridX = max(0, min(1, relativeX / (itemWidth + 12)))
        let gridY = max(0, relativeY / itemHeight)

        return CGPoint(x: gridX, y: gridY)
    }
    
    private func calculatePreviewOffset(for channel: SavedChannel, draggedItem: SavedChannel?, dragOffset: CGSize, in geometry: GeometryProxy) -> CGSize {
        guard let draggedItem = draggedItem, draggedItem.id != channel.id else {
            return .zero
        }

        // Get current positions
        guard let draggedIndex = viewModel.savedChannels.firstIndex(where: { $0.id == draggedItem.id }),
              let currentIndex = viewModel.savedChannels.firstIndex(where: { $0.id == channel.id }) else {
            return .zero
        }

        // Calculate where the dragged item would be placed relative to the grid
        let draggedCenter = CGPoint(
            x: geometry.frame(in: .global).midX + dragOffset.width,
            y: geometry.frame(in: .global).midY + dragOffset.height
        )
        let gridLocation = convertToGridCoordinates(draggedCenter, in: geometry)

        // Calculate target index for the dragged item
        let targetColumn = Int(round(gridLocation.x))
        let targetRow = Int(round(gridLocation.y))
        let targetIndex = targetRow * 2 + targetColumn
        let clampedTargetIndex = max(0, min(targetIndex, viewModel.savedChannels.count))

        // Calculate how the current item should move to make room for the dragged item
        if currentIndex < draggedIndex {
            // This item is before the dragged item in the array
            if clampedTargetIndex <= currentIndex {
                // Dragged item will be inserted before or at this position
                return CGSize(width: 0, height: 72) // Move down
            }
        } else if currentIndex > draggedIndex {
            // This item is after the dragged item in the array
            if clampedTargetIndex > currentIndex {
                // Dragged item will be inserted after this position
                return CGSize(width: 0, height: -72) // Move up
            } else if clampedTargetIndex <= currentIndex && clampedTargetIndex > draggedIndex {
                // Dragged item moved from before to after this item
                return CGSize(width: 0, height: -72) // Move up
            }
        }

        return .zero
    }

    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    headerView
                    
                    VStack(spacing: 20) {
                        Spacer().frame(height: 15)
                        
                        savedChannelsGrid
                        
                        messageArea
                        
                        channelNameInputSection
                        
                        searchChannelButton
                        
                        if config.showChannelIdInput {
                            channelIdInputSection
                        }
                        
                        videoSettingsSection
                        
                        actionButtonsSection
                        
                        videoListSection
                    }
                    .padding(.bottom, 24)
                }
                .onAppear {
                    self.scrollProxy = proxy
                }
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
        .overlay(
            Group {
                if viewModel.showEditDialog {
                    SimpleEditDialog(
                        channelName: $viewModel.editChannelName,
                        channelColor: $viewModel.editChannelColor,
                        onSave: {
                            viewModel.saveEditedChannel()
                        },
                        onCancel: {
                            viewModel.cancelEdit()
                        }
                    )
                }
            }
        )
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 8) {
            #if targetEnvironment(macCatalyst)
            Spacer().frame(height: 5)
            #endif
            
            HStack {
                Spacer()
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(AppButtonStyle())
                .padding(.trailing, -20)
                .focusable(false)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

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
        .padding(.bottom, 0)
    }

    private var savedChannelsGrid: some View {
        Group {
            if !viewModel.savedChannels.isEmpty {
                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if anyDeleteModeActive {
                                anyDeleteModeActive = false
                            }
                        }

                    GeometryReader { geometry in
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(Array(viewModel.savedChannels.enumerated()), id: \.element.id) { index, channel in
                                SavedChannelButton(
                                    channel: channel,
                                    onTap: { viewModel.selectSavedChannel(channel) },
                                    onLongPress: { viewModel.deleteSavedChannel(channel) },
                                    onEdit: { viewModel.editSavedChannel(channel) },
                                    globalDeleteMode: $anyDeleteModeActive,
                                    isDragging: draggedItem?.id == channel.id,
                                    dragOffset: draggedItem?.id == channel.id ? dragOffset : .zero,
                                    previewOffset: calculatePreviewOffset(for: channel, draggedItem: draggedItem, dragOffset: dragOffset, in: geometry),
                                    onDragChanged: { offset in dragOffset = offset },
                                    onDragStarted: { draggedItem = channel; dragOffset = .zero },
                                    onDragEnded: { location in
                                        if let draggedItem = draggedItem {
                                            let gridLocation = convertToGridCoordinates(location, in: geometry)
                                            viewModel.reorderChannel(from: draggedItem, to: gridLocation)
                                        }
                                        draggedItem = nil
                                        dragOffset = .zero
                                    }
                                )
                            }
                        }
                    }
                    .frame(height: CGFloat((viewModel.savedChannels.count + 1) / 2) * 72)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var messageArea: some View {
        Group {
            if let message = viewModel.message, !config.apiKey.isEmpty {
                MessageView(
                    message: message,
                    type: viewModel.messageType,
                    onPlusTap: viewModel.showChannelSavePrompt ? { viewModel.saveCurrentChannel() } : nil,
                    onTap: viewModel.showChannelSavePrompt ? { viewModel.saveCurrentChannel() } : nil
                )
                .padding(.horizontal, 24)
            }
            if config.apiKey.isEmpty && viewModel.message == nil {
                MessageView(message: "Please add your YouTube API key in Settings to get started.", type: .info)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var channelNameInputSection: some View {
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
    }

    private var searchChannelButton: some View {
        Button(action: {
            Task {
                await viewModel.searchChannel(config: config)
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
        .buttonStyle(AppButtonStyle())
        .disabled(viewModel.channelName.isEmpty || viewModel.isLoading)
        .padding(.horizontal, 24)
    }

    private var channelIdInputSection: some View {
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
    }

    private var videoSettingsSection: some View {
        Group {
            Text("Video Settings")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 10)

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
                    #if os(iOS)
                    .keyboardType(.decimalPad)
#endif
                    .disableAutocorrection(true)
                    .disabled(viewModel.isLoading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)

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
        }
    }

    private var actionButtonsSection: some View {
        Group {
            // Only show "Get Video IDs" button when no videos fetched yet
            if viewModel.videoIds.isEmpty {
                Button(action: {
                    Task {
                        await viewModel.fetchVideos(config: config)
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text(" Fetching videos...")
                                .font(.system(size: 17, weight: .semibold))
                        } else {
                            Image(systemName: "play.circle")
                            Text("Get Video IDs")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.isLoading ? Color(hex: "#30D158") : (viewModel.canFetchVideos(apiKey: config.apiKey) ? Color(hex: "#007AFF") : Color(hex: "#2C2C2E")))
                    .foregroundColor(viewModel.canFetchVideos(apiKey: config.apiKey) ? .white : Color(hex: "#8E8E93"))
                    .cornerRadius(16)
                }
                .buttonStyle(AppButtonStyle())
                .disabled(!viewModel.canFetchVideos(apiKey: config.apiKey) || viewModel.isLoading)
                .padding(.horizontal, 24)
            }

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
                    .background(Color(hex: "#FF3B30")) // Vibrant YouTube Red
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(AppButtonStyle())
                .padding(.horizontal, 24)

                #if targetEnvironment(macCatalyst) || os(macOS)
                Button(action: {
                    viewModel.downloadAudio()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Download Audio")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#5D3FD3")) // Iris - Sophisticated Premium Purple
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(AppButtonStyle())
                .padding(.horizontal, 24)
                #endif
            }
        }
    }

    private var videoListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.videos.isEmpty {
                HStack {
                    Text("Retrieved Videos")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#8E8E93"))
                    
                    Spacer()
                    
                    Text("\(viewModel.videos.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .id("videoIdsSection")

                VStack(spacing: 8) {
                    ForEach(viewModel.videos) { video in
                        Button(action: {
                            viewModel.openVideo(id: video.id)
                        }) {
                            HStack(spacing: 12) {
                                // Thumbnail with duration badge
                                ZStack {
                                    if let urlString = video.thumbnailUrl, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { image in
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.white.opacity(0.05)
                                        }
                                        .frame(width: 100, height: 56)
                                        .cornerRadius(8)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                            .frame(width: 100, height: 56)
                                    }
                                    
                                    // Duration badge
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Text(video.formattedDuration)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Color.black.opacity(0.75))
                                                .cornerRadius(4)
                                                .padding(4)
                                        }
                                    }
                                }
                                .frame(width: 100, height: 56)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(video.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.3))
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(10)
                        }
                        .buttonStyle(AppButtonStyle())
                        .padding(.horizontal, 24)
                    }
                }
            }
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
    var onPlusTap: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

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

    private var showPlusButton: Bool {
        return type == .success && message.contains("Found channel:") && onPlusTap != nil
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if !showPlusButton {
                        Image(systemName: iconName)
                            .foregroundColor(foregroundColor)
                    }
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
            .onTapGesture {
                onTap?()
            }

            if showPlusButton {
                Button(action: {
                    onPlusTap?()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "#30D158"))
                }
                .buttonStyle(AppButtonStyle())
                .offset(x: 8, y: -8)
            }
        }
    }
}

struct DragState {
    var translation: CGSize = .zero
    var isDragging: Bool = false
    
    static let inactive = DragState()
}

struct SavedChannelButton: View {
    let channel: SavedChannel
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onEdit: () -> Void
    @Binding var globalDeleteMode: Bool
    let isDragging: Bool
    let dragOffset: CGSize
    let previewOffset: CGSize
    let onDragChanged: (CGSize) -> Void
    let onDragStarted: () -> Void
    let onDragEnded: (CGPoint) -> Void

    @State private var isDeleteMode = false
    @State private var isDraggingLocal = false
    @GestureState private var dragState = DragState.inactive

    var body: some View {
        ZStack {
            ZStack {
                Color(hex: channel.colorHex)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(height: 60)
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)

                Text(channel.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
            }
            .offset(isDragging ? dragOffset : previewOffset)
            .animation(.interactiveSpring(), value: isDragging)
            .animation(.easeInOut(duration: 0.2), value: previewOffset)

            if isDeleteMode {
                Button(action: {
                    onEdit()
                    isDeleteMode = false
                    globalDeleteMode = false
                }) {
                    ZStack {
                        Color.white.opacity(0.4)
                            .ignoresSafeArea()
                            .cornerRadius(12)
                        
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .font(.system(size: 37, weight: .medium))
                            .opacity(0.8)
                    }
                }
                .buttonStyle(AppButtonStyle())
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            onLongPress()
                            isDeleteMode = false
                            globalDeleteMode = false
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(Color(hex: "#ff0000"))
                        }
                        .buttonStyle(AppButtonStyle())
                        .offset(x: 8, y: -8)
                    }
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDraggingLocal {
                        isDraggingLocal = true
                        onDragStarted()
                    }
                    onDragChanged(value.translation)
                }
                .onEnded { value in
                    isDraggingLocal = false
                    onDragEnded(value.location)
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if !isDraggingLocal {
                        isDeleteMode = true
                        globalDeleteMode = true
                    }
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    if isDeleteMode {
                        isDeleteMode = false
                        globalDeleteMode = false
                    } else if !isDraggingLocal {
                        onTap()
                    }
                }
        )
        .onChange(of: globalDeleteMode) { newValue in
            if !newValue {
                isDeleteMode = false
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: - Simple Edit Dialog
struct SimpleEditDialog: View {
    @Binding var channelName: String
    @Binding var channelColor: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    private let colorOptions = [
        "#4A148C", "#6A1B9A", "#7B1FA2", "#8E24AA", "#9C27B0", "#BA68C8", "#CE93D8", "#E1BEE7",
        "#2E3440", "#3B4252", "#434C5E", "#4C566A", "#88C0D0", "#81A1C1", "#5E81AC", "#A3BE8C",
        "#8FBCBB", "#D08770", "#EBCB8B", "#BF616A", "#B48EAD", "#5E81AC", "#A3BE8C", "#D08770"
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            VStack(spacing: 16) {
                HStack {
                    Spacer()

                    Button(action: {
                        onSave()
                    }) {
                        Text("Save")
                    }
                    .buttonStyle(AppButtonStyle())
                    .foregroundColor(Color(hex: "#007AFF"))
                    .disabled(channelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    TextField("Channel name", text: $channelName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .disableAutocorrection(true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button(action: {
                                channelColor = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: channelColor == color ? 2 : 0)
                                    )
                            }
                            .buttonStyle(AppButtonStyle())
                        }
                    }
                }
            }
            .frame(maxWidth: 400)
            .padding(20)
            .background(Color(hex: "#141415"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
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
            Button(action: {
                #if targetEnvironment(macCatalyst)
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
            .buttonStyle(AppButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(VideoOrder.sortedCases, id: \.self) { order in
                        Button(action: {
                            selectedOrder = order
                            #if targetEnvironment(macCatalyst)
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
                        .buttonStyle(AppButtonStyle())
                        
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
            (a, r, g, b) = (255, 1, 1, 0)
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
// MARK: - Custom Button Style for clean interaction
private struct AppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
