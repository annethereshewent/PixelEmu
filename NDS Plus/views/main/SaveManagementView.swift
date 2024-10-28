//
//  SaveManagementView.swift
//  NDS Plus
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
    @State private var localSaves: [SaveEntry] = []
    @State private var cloudEntry: SaveEntry? = nil
    @State private var localEntry: SaveEntry? = nil
    @State private var isPresented = false
    @State private var showDeleteDialog = false
    @State private var loading = false
    @State private var showDownloadAlert = false
    @State private var showDeleteAlert = false
    @State private var showUploadAlert = false
    @State private var showErrorAlert = false
    @State private var deleteAction: () -> Void = {}

    @Query private var games: [Game]

    private let successTitle = "Success!"

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
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
                saveEntries = await cloudService!.getSaves(games: games)
            }
        }
    }
    
    var body: some View {
        ZStack {
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
                
                ScrollView {
                    if saveEntries.count > 0 {
                        Text("Cloud saves")
                            .foregroundColor(Colors.primaryColor)
                        LazyVGrid(columns: columns) {
                            ForEach(saveEntries, id: \.game.gameName) { saveEntry in
                                GameEntryView(game: saveEntry.game) {
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
                        Text("Local saves")
                            .foregroundColor(Colors.primaryColor)
                        LazyVGrid(columns: columns) {
                            ForEach(localSaves, id: \.game.gameName) { saveEntry in
                                GameEntryView(game: saveEntry.game) {
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
            }
            .onAppear {
                let defaults = UserDefaults.standard

                if let themeColor = defaults.value(forKey: "themeColor") as? Color {
                    self.themeColor = themeColor
                }

                if user != nil {
                    loading = true
                    Task {
                        if let saveEntries = await cloudService?.getSaves(games: games) {
                            self.saveEntries = saveEntries
                        }
                        loading = false
                    }
                }
                // get any local saves
                localSaves = BackupFile.getLocalSaves(games: games)
            }
            .font(.custom("Departure Mono", size: 20))
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
