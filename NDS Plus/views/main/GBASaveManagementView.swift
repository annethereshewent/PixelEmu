//
//  GBASaveManagementView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 12/5/24.
//

import SwiftUI
import SwiftData
import GoogleSignIn

struct GBASaveManagementView: View {
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    @State var localEntry: GBASaveEntry? = nil
    @State var localSaves: [GBASaveEntry] = []

    @Binding var saveEntries: [GBASaveEntry]
    @Binding var cloudEntry: GBASaveEntry?

    @Binding var user: GIDGoogleUser?
    @Binding var loading: Bool
    @Binding var cloudService: CloudService?
    @Binding var themeColor: Color

    @Query private var games: [GBAGame]

    var body: some View {
        ScrollView {
            if saveEntries.count > 0 {
                Text("GBA cloud saves")
                    .foregroundColor(Colors.primaryColor)
                LazyVGrid(columns: columns) {
                    ForEach(saveEntries, id: \.game.gameName) { saveEntry in
                        GBAEntryView(themeColor: $themeColor, game: saveEntry.game) {
                            if cloudEntry == saveEntry {
                                cloudEntry = nil

                            } else {
                                cloudEntry = saveEntry
                            }
                        }
                        .foregroundColor(Colors.primaryColor)
                    }
                    .presentationCompactAdaptation(.popover)
                    .padding(.leading, 20)
                }
            }
            if localSaves.count > 0 {
                Text("GBA local saves")
                    .foregroundColor(Colors.primaryColor)
                LazyVGrid(columns: columns) {
                    ForEach(localSaves, id: \.game.gameName) { saveEntry in
                        GBAEntryView(themeColor: $themeColor, game: saveEntry.game) {
                            if localEntry == saveEntry {
                                localEntry = nil
                            } else {
                                localEntry = saveEntry
                            }
                        }
                        .foregroundColor(Colors.primaryColor)
                    }
                }
            }
            if loading {
                ProgressView()
            }

        }
        .onAppear {
            if user != nil {
                loading = true
                Task {
                    if let saveEntries = await cloudService?.getGbaSaves(games: games) {
                        self.saveEntries = saveEntries
                    }
                    loading = false
                }
            }
            // get any local saves
            localSaves = BackupFile.getLocalGBASaves(games: games)
        }
    }
}
