//
//  SaveManagementView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/24/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import SwiftData

struct SaveManagementView: View {
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    @Binding var themeColor: Color

    @State private var saveEntries: [SaveEntry] = []
    @State private var gbaSaveEntries: [SaveEntry] = []
    @State private var gbcSaveEntries: [SaveEntry] = []
    @State private var cloudEntry: SaveEntry? = nil
    @State private var isPresented = false
    @State private var loading = false

    @Query private var games: [Game]
    @Query private var gbaGames: [GBAGame]
    @Query private var gbcGames: [GBCGame]

    private func handleSignInButton() {
        guard let rootViewController = (UIApplication.shared.connectedScenes.first
                  as? UIWindowScene)?.windows.first?.rootViewController
        else {
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            guard let result = signInResult else {
                print(error!)
                return
            }

            user = result.user
            cloudService = CloudService(user: user!)
            Task {
                saveEntries = await cloudService!.getSaves(games: games, saveType: .nds)
                gbaSaveEntries = await cloudService!.getSaves(games: gbaGames, saveType: .gba)
                gbcSaveEntries = await cloudService!.getSaves(games: gbcGames, saveType: .gbc)
            }
        }
    }

    var body: some View {
        VStack {
            Text("Save management")
                .font(.custom("Departure Mono", size: 24))
                .fontWeight(.bold)
                .foregroundColor(Colors.primaryColor)
            if user == nil {
                HStack {
                    Button("Sign in to Google") {
                        handleSignInButton()
                    }
                    .foregroundColor(themeColor)
                }
            } else {
                Button("Sign out of Google") {
                    GIDSignIn.sharedInstance.signOut()
                    user = nil
                    saveEntries = []
                    cloudService = nil
                    cloudEntry = nil
                }
                .foregroundColor(themeColor)
            }
            TabView {
                MainSaveManagementView(
                    gameType: .gbc,
                    saveEntries: $gbcSaveEntries,
                    cloudEntry: $cloudEntry,
                    user: $user,
                    loading: $loading,
                    cloudService: $cloudService,
                    themeColor: $themeColor
                )
                MainSaveManagementView(
                    gameType: .gba,
                    saveEntries: $gbaSaveEntries,
                    cloudEntry: $cloudEntry,
                    user: $user,
                    loading: $loading,
                    cloudService: $cloudService,
                    themeColor: $themeColor
                )
                MainSaveManagementView(
                    gameType: .nds,
                    saveEntries: $saveEntries,
                    cloudEntry: $cloudEntry,
                    user: $user,
                    loading: $loading,
                    cloudService: $cloudService,
                    themeColor: $themeColor
                )
            }.tabViewStyle(.page)
        }
        .font(.custom("Departure Mono", size: 20))
    }

}
