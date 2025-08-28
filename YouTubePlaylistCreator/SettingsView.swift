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
            // Dark background
            Color(hex: "#000000")
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header with Done button (only show if dismiss action is available)
                if dismissAction != nil {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismissAction?()
                        }) {
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(hex: "#007AFF"))
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                }

                // Main content
                VStack(spacing: 20) {
                    // YouTube API Section - At top
                    VStack(alignment: .leading, spacing: 16) {
                        Text("YouTube API")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("API Key")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: "#8E8E93"))

                                ZStack(alignment: .trailing) {

                                    if showApiKey {
                                        TextField("", text: $config.apiKey)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                            .padding(.trailing, 50) // Space for the button
                                            .foregroundColor(.white)
                                            .disableAutocorrection(true)
                                            .autocapitalization(.none)
                                    } else {
                                        SecureField("", text: $config.apiKey)
                                            .textFieldStyle(PlainTextFieldStyle())
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
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
                                .background(Color(hex: "#1C1C1E"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#1C1C1E"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )



                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                // Version info at bottom
                VStack(spacing: 8) {
                    Text(appVersion)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

