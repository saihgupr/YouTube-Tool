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

    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "#000000")
                .ignoresSafeArea()

            VStack(spacing: 0) {
        

                // Main content
                VStack(spacing: 20) {
                    // Video Settings Section - Moved to top
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Video Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Maximum Videos")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: "#8E8E93"))

                                HStack {
                                    Text("\(config.maxVideosLimit)")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 40, alignment: .leading)
                                    Spacer()
                                    Stepper("", value: $config.maxVideosLimit, in: 10...100, step: 5)
                                }
                                .padding(16)
                                .background(Color(hex: "#2C2C2E"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )

                                Text("Number of videos to fetch (10-100)")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "#8E8E93"))
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

                    // YouTube API Section - Moved below video settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("YouTube API")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("API Key")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: "#8E8E93"))

                                ZStack(alignment: .leading) {
                                    if config.apiKey.isEmpty {
                                        Text("AIzaSyBxgo…")
                                            .foregroundColor(Color(hex: "#8E8E93"))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                    }
                                    SecureField("", text: $config.apiKey)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(16)
                                        .background(Color(hex: "#1C1C1E"))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .disableAutocorrection(true)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                }
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

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Version info at bottom
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    Text("v1.0")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(width: 450, height: 400)
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

