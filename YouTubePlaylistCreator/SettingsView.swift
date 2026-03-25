//
//  SettingsView.swift
//  YouTubePlaylistCreator
//
//  Settings view for Mac Catalyst
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var config: Config
    @State private var showApiKey = false
    @State private var showApiHelp = false

#if canImport(AppKit)
    // No dismiss needed for native Mac usually, or handled by view state
#endif


    // Dismiss action for older Mac Catalyst versions
    var dismissAction: (() -> Void)?

    // Get app version from bundle
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "v\(version)"
        }
        return "v1.0" // Fallback
    }

    var body: some View {
        ZStack {
            // Dark background - match web version
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header - match main page styling
                VStack(spacing: 8) {
                    // Back button only
                    HStack {
                        Button(action: {
                            dismissAction?()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
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
                        .focusable(false)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    // Title and subtitle - match main page
                    VStack(spacing: 8) {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Configure your YouTube API settings")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#8E8E93"))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 0)

                // Main content - match main page spacing
                VStack(spacing: 15) {
                    // Add padding below subtitle - match main page
                    Spacer()
                        .frame(height: 15)

                    // YouTube API Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YouTube API Key:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        ZStack(alignment: .trailing) {
                            if showApiKey {
                                TextField("Enter your YouTube Data API v3 key", text: $config.apiKey)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 12)
                                    .padding(.trailing, 50)
                                    .foregroundColor(.white)
                                    #if !os(macOS)
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                                    #endif
                            } else {
                                SecureField("Enter your YouTube Data API v3 key", text: $config.apiKey)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 12)
                                    .padding(.trailing, 50)
                                    .foregroundColor(.white)
                                    .textContentType(.password)
                                    #if !os(macOS)
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                                    #endif
                            }

                            // Eye button
                            Button(action: {
                                showApiKey.toggle()
                            }) {
                                Image(systemName: showApiKey ? "eye" : "eye.slash")
                                    .foregroundColor(Color(hex: "#8E8E93"))
                                    .padding(.trailing, 16)
                            }
                            .buttonStyle(AppButtonStyle())
                        }
                        .background(Color(hex: "#000000").opacity(0.3))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                        // Help link under the input
                        Button(action: {
                            showApiHelp = true
                        }) {
                            Text("Get YouTube API key")
                                .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#8E8E93"))
                        }
                        .buttonStyle(AppButtonStyle())
                    }
                    .padding(.horizontal, 24)

                    // Application Settings Section - match main page layout
                    VStack(alignment: .leading, spacing: 12) {
                        // Auto-open YouTube links toggle - match YouTube Shorts style exactly
                        HStack {
                            Text("Auto-open YouTube Links")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#8E8E93"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                            Toggle("", isOn: $config.autoOpenYouTubeLinks)
                                .labelsHidden()
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

                        // Show Channel ID input toggle - match YouTube Shorts style exactly
                        HStack {
                            Text("Show Channel ID Input")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#8E8E93"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                            Toggle("", isOn: $config.showChannelIdInput)
                                .labelsHidden()
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
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.bottom, 24)

                // Version info at bottom - match web version styling
                VStack(spacing: 8) {
                    Text(appVersion)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // API Help Sheet
            .sheet(isPresented: $showApiHelp) {
                ApiHelpView(dismissAction: { showApiHelp = false })
            }
        }
    }
}


// MARK: - API Help Sheet
struct ApiHelpView: View {
    var dismissAction: (() -> Void)?

    var body: some View {
        ZStack {
            Color(hex: "#1C1C1E").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { dismissAction?() }) {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(hex: "#007AFF"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .buttonStyle(AppButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Title
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Text("🔑")
                            .font(.system(size: 28))
                        Text("Get a Google API Key")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("Create a YouTube Data API v3 key and paste it into Settings")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#8E8E93"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)

                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    HelpStep(number: "1", text: "Open Google Cloud Console and sign in with your Google account.")
                    HelpStep(number: "2", text: "Create a new project (or select an existing one).")
                    HelpStep(number: "3", text: "Go to APIs & Services → Library and enable 'YouTube Data API v3'.")
                    HelpStep(number: "4", text: "Go to APIs & Services → Credentials → Create credentials → API key.")
                    HelpStep(number: "5", text: "Copy the API key and paste it into Settings.")
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Open Console Button
                Button(action: {
                    if let url = URL(string: "https://console.cloud.google.com/") {
                        #if targetEnvironment(macCatalyst)
                        UIApplication.shared.open(url)
                        #elseif os(macOS)
                        NSWorkspace.shared.open(url)
                        #else
                        UIApplication.shared.open(url)
                        #endif
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("Open Google Cloud Console")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#000000").opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(AppButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()
            }
        }
    }
}

struct HelpStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#8E8E93"))
                .frame(width: 22, height: 22)
                .background(Color.white.opacity(0.08))
                .cornerRadius(11)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#E5E5EA"))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
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
