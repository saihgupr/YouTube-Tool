//
//  SettingsView.swift
//  YouTubePlaylistCreator
//
//  Created by Chris Lapointe
//  Settings view for Mac Catalyst
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var config: Config
    @State private var showApiKey = false
    @State private var showApiHelp = false

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
                // Header - match web version styling
                VStack(spacing: 8) {
                    // Settings button in top right
                    HStack {
                        Spacer()
                        Button(action: {
                            dismissAction?()
                        }) {
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(hex: "#007AFF"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)

                    // Title and subtitle - match web version
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Text("⚙️")
                                .font(.system(size: 32))
                            Text("Settings")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Configure your YouTube API settings")
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
                                    .padding(.trailing, 50) // Space for the button
                                    .foregroundColor(.white)
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Enter your YouTube Data API v3 key", text: $config.apiKey)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 12)
                                    .padding(.trailing, 50) // Space for the button
                                    .foregroundColor(.white)
                                    .disableAutocorrection(true)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                            }

                            // Eye button
                            Button(action: {
                                showApiKey.toggle()
                            }) {
                                Image(systemName: showApiKey ? "eye" : "eye.slash")
                                    .foregroundColor(Color(hex: "#8E8E93"))
                                    .padding(.trailing, 16)
                            }
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
                        .buttonStyle(PlainButtonStyle())
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
                            .background(Color.white.opacity(0.0))
                            .cornerRadius(8)
                    }
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

