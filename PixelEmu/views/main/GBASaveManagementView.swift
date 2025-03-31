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

    @State private var showDownloadAlert = false
    @State private var showDeleteAlert = false
    @State private var showUploadAlert = false
    @State private var showErrorAlert = false
    @State private var showDeleteDialog = false

    @State private var deleteAction: () -> Void = {}

    @Binding var saveEntries: [GBASaveEntry]
    @Binding var cloudEntry: GBASaveEntry?

    @Binding var user: GIDGoogleUser?
    @Binding var loading: Bool
    @Binding var cloudService: CloudService?
    @Binding var themeColor: Color

    @Query private var games: [GBAGame]

    private let successTitle = "Success!"

    var body: some View {
        ZStack {
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
            .onTapGesture {
                cloudEntry = nil
                localEntry = nil

                showDownloadAlert = false
                showUploadAlert = false
                showErrorAlert = false
                showDeleteAlert = false
            }
            if cloudEntry != nil {
                GBAEntryModal(
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
                GBAEntryModal(
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
