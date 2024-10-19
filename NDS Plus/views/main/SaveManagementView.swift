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
    
    @Query private var games: [Game]
    
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
                        .foregroundColor(Colors.accentColor)
                    }
                } else {
                    Button("Sign out of Google") {
                        GIDSignIn.sharedInstance.signOut()
                        user = nil
                        saveEntries = []
                        cloudService = nil
                        cloudEntry = nil
                    }
                    .foregroundColor(Colors.accentColor)
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
                    showDeleteDialog: $showDeleteDialog,
                    showDownloadAlert: $showDownloadAlert,
                    showUploadAlert: $showUploadAlert,
                    showErrorAlert: $showErrorAlert,
                    showDeleteAlert: $showDeleteAlert,
                    isCloudSave: true
                )
            } else if localEntry != nil {
                GameEntryModal(
                    entry: $localEntry,
                    localSaves: $localSaves,
                    cloudSaves: $saveEntries,
                    cloudService: $cloudService,
                    loading: $loading,
                    showDeleteDialog: $showDeleteDialog,
                    showDownloadAlert: $showDownloadAlert,
                    showUploadAlert: $showUploadAlert,
                    showErrorAlert: $showErrorAlert,
                    showDeleteAlert: $showDeleteAlert,
                    isCloudSave: false
                )
            } else if showDownloadAlert {
                AlertModal(text: "Successfully downloaded save.", showAlert: $showDownloadAlert)
            } else if showUploadAlert {
                AlertModal(text: "Successfully uploaded save.", showAlert: $showUploadAlert)
            } else if showDeleteAlert {
                AlertModal(text: "Successfully deleted save.", showAlert: $showDeleteAlert)
            } else if showErrorAlert {
                ErrorAlertModal(showAlert: $showErrorAlert)
            }
        }
    }
}
