//
//  MainSaveManagementView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 12/5/24.
//

import SwiftUI
import SwiftData
import GoogleSignIn

struct MainSaveManagementView: View {
    let gameType: GameType
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    @Binding var saveEntries: [SaveEntry]
    @Binding var cloudEntry: SaveEntry?
    @Binding var user: GIDGoogleUser?
    @Binding var loading: Bool
    @Binding var cloudService: CloudService?
    @Binding var themeColor: Color

    @State private var showDownloadAlert = false
    @State private var showDeleteAlert = false
    @State private var showUploadAlert = false
    @State private var showErrorAlert = false
    @State private var showDeleteDialog = false
    @State private var localSaves: [SaveEntry] = []
    @State private var localEntry: SaveEntry? = nil

    @State private var deleteAction: () -> Void = {}

    @Query private var games: [Game]
    @Query private var gbaGames: [GBAGame]
    @Query private var gbcGames: [GBCGame]

    private let successTitle = "Success!"

    var body: some View {
        ZStack {
            ScrollView {
                if saveEntries.count > 0 {
                    Text("\(gameType.getConsoleName()) cloud saves")
                        .foregroundColor(Colors.primaryColor)
                    LazyVGrid(columns: columns) {
                        ForEach(saveEntries, id: \.game.gameName) { saveEntry in
                            GameEntryView(game: saveEntry.game, themeColor: $themeColor) {
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
                    Text("\(gameType.getConsoleName()) local saves")
                        .foregroundColor(Colors.primaryColor)
                    LazyVGrid(columns: columns) {
                        ForEach(localSaves, id: \.game.gameName) { saveEntry in
                            GameEntryView(game: saveEntry.game, themeColor: $themeColor) {
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
                    if games.count > 0 {
                        loading = true
                        Task {
                            switch gameType {
                            case .nds:
                                if let saveEntries = await cloudService?.getSaves(games: games, saveType: .nds) {
                                    self.saveEntries = saveEntries
                                }
                                loading = false
                            case .gba:
                                if let saveEntries = await cloudService?.getSaves(games: gbaGames, saveType: .gba) {
                                    self.saveEntries = saveEntries
                                }
                                loading = false
                            case .gbc:
                                if let saveEntries = await cloudService?.getSaves(games: gbcGames, saveType: .gbc) {
                                    self.saveEntries = saveEntries
                                } else {
                                    print("couldn't find em!")
                                }
                            }

                        }
                    }
                }
                // get any local saves
                switch gameType {
                case .nds: localSaves = BackupFile.getLocalSaves(games: games)
                case .gba: localSaves = BackupFile.getLocalGBASaves(games: gbaGames)
                case .gbc: break
                }
            }
            .onTapGesture {
                cloudEntry = nil
                localEntry = nil

                showDownloadAlert = false
                showUploadAlert = false
                showErrorAlert = false
                showDeleteAlert = false
            }
            if cloudEntry != nil {
                GameEntryModal(
                    entry: $cloudEntry,
                    localSaves: $localSaves,
                    cloudSaves: $saveEntries,
                    cloudService: $cloudService,
                    loading: $loading,
                    showDownloadAlert: $showDownloadAlert,
                    showUploadAlert: $showUploadAlert,
                    showErrorAlert: $showErrorAlert,
                    showDeleteAlert: $showDeleteAlert,
                    showDeleteDialog: $showDeleteDialog,
                    deleteAction: $deleteAction,
                    themeColor: $themeColor,
                    isCloudSave: true
                )
            } else if localEntry != nil {
                GameEntryModal(
                    entry: $localEntry,
                    localSaves: $localSaves,
                    cloudSaves: $saveEntries,
                    cloudService: $cloudService,
                    loading: $loading,
                    showDownloadAlert: $showDownloadAlert,
                    showUploadAlert: $showUploadAlert,
                    showErrorAlert: $showErrorAlert,
                    showDeleteAlert: $showDeleteAlert,
                    showDeleteDialog: $showDeleteDialog,
                    deleteAction: $deleteAction,
                    themeColor: $themeColor,
                    isCloudSave: false
                )
            } else if showDownloadAlert {
                AlertModal(
                    alertTitle: successTitle,
                    text: "Successfully downloaded save.",
                    showAlert: $showDownloadAlert,
                    themeColor: $themeColor
                )
            } else if showUploadAlert {
                AlertModal(
                    alertTitle: successTitle,
                    text: "Successfully uploaded save.",
                    showAlert: $showUploadAlert,
                    themeColor: $themeColor
                )
            } else if showDeleteAlert {
                AlertModal(
                    alertTitle: successTitle,
                    text: "Successfully deleted save.",
                    showAlert: $showDeleteAlert,
                    themeColor: $themeColor
                )
            } else if showErrorAlert {
                AlertModal(
                    alertTitle: "Oops!",
                    text: "There was an error performing the action.",
                    showAlert: $showErrorAlert,
                    themeColor: $themeColor
                )
            } else if showDeleteDialog {
                DeleteDialog(
                    showDialog: $showDeleteDialog,
                    deleteAction: $deleteAction,
                    themeColor: $themeColor,
                    deleteMessage: "Are you sure you want to delete this save?"
                )
            }
        }
    }
}
