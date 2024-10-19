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
import UniformTypeIdentifiers

struct SaveManagementView: View {
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    
    @State private var saveEntries: [SaveEntry] = []
    @State private var localSaves: [SaveEntry] = []
    @State private var cloudEntry: SaveEntry? = nil
    @State private var localEntry: SaveEntry? = nil
    @State private var isPresented = false
    @State private var showDeleteDialog = false
    // remove this maybe
    @State private var showLocalDelete = false
    @State private var loading = false
    @State private var showDownloadAlert = false
    @State private var showDeleteAlert = false
    @State private var showUploadAlert = false
    @State private var showErrorAlert = false
    @State private var deleteAction: () -> Void = {}
    @State private var isPopoverPresented = false
    
    @Query private var games: [Game]
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    let savType = UTType(filenameExtension: "sav", conformingTo: .data)
    
    private func downloadCloudSave() {
        // download save for offline use
        let saveName = cloudEntry!.game.gameName.replacing(".nds" ,with: ".sav")
        
        loading = true
        Task {
            if let save = await cloudService?.getSave(saveName: saveName) {
                BackupFile.saveCloudFile(saveName: saveName, saveFile: save)
                let saveEntry = SaveEntry(game: cloudEntry!.game)
                if !localSaves.contains(saveEntry) {
                    localSaves.append(saveEntry)
                }
                showDownloadAlert = true
            } else {
                showErrorAlert = true
            }
            loading = false
        }
    }
    
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
                Text("Save Management")
                    .font(.custom("Departure Mono", size: 24))
                    .fontWeight(.bold)
                if user == nil {
                    HStack {
                        Button("Sign in to Google") {
                            handleSignInButton()
                        }
                        .foregroundColor(Colors.accentColor)
                    }
                } else {
                    Button("Sign Out of Google") {
                        GIDSignIn.sharedInstance.signOut()
                        user = nil
                        saveEntries = []
                        cloudService = nil
                        cloudEntry = nil
                        isPopoverPresented = false
                    }
                    .foregroundColor(Colors.accentColor)
                }
                
                ScrollView {
                    Text("Cloud Saves")
                    LazyVGrid(columns: columns) {
                        ForEach(saveEntries, id: \.game.gameName) { saveEntry in
                            GameEntryView(game: saveEntry.game) {
                                if cloudEntry == saveEntry {
                                    cloudEntry = nil
                                    isPopoverPresented = false
                                    print("mama mia im a hiding the popover!")
                                } else {
                                    cloudEntry = saveEntry
                                    isPopoverPresented = true
                                    print("mamma mia im a presenting the popover!")
                                }
                            }
                        }
                        .presentationCompactAdaptation(.popover)
                        .padding(.leading, 20)
                    }
                    Text("Local saves")
                    LazyVGrid(columns: columns) {
                        ForEach(localSaves, id: \.game.gameName) { saveEntry in
                            GameEntryView(game: saveEntry.game) {
                                if localEntry == saveEntry {
                                    localEntry = nil
                                } else {
                                    localEntry = saveEntry
                                }
                            }
                        }
                    }
                    if loading {
                        ProgressView()
                    }
                    
                }
            }
            .fileImporter(isPresented: $isPresented, allowedContentTypes: [savType!]) { result in
                // upload the result to google cloud
                do {
                    let url = try result.get()
                    
                    if url.startAccessingSecurityScopedResource() {
                        defer {
                            url.stopAccessingSecurityScopedResource()
                        }
                        
                        let data = try Data(contentsOf: url)
                        loading = true
                        Task {
                            await cloudService?.uploadSave(
                                saveName: cloudEntry!.game.gameName.replacing(".nds", with: ".sav"),
                                data: data
                            )
                            showUploadAlert = true
                        }
                    }
                } catch {
                    print(error)
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
            .confirmationDialog("Confirm delete", isPresented: $showDeleteDialog) {
                Button("Delete save?", role: .destructive, action: deleteAction)
            }
            .font(.custom("Departure Mono", size: 20))
            .alert("Successfully uploaded save", isPresented: $showUploadAlert) {
                Button("Ok", role: .cancel) {
                    showUploadAlert = false
                    cloudEntry = nil
                    localEntry = nil
                    isPopoverPresented = false
                }
            }
            .alert("Successfully deleted save", isPresented: $showDeleteAlert) {
                Button("Ok", role: .cancel) {
                    showDeleteAlert = false
                    cloudEntry = nil
                    localEntry = nil
                    isPopoverPresented = false
                }
            }
            .alert("Save downloaded successfully", isPresented: $showDownloadAlert) {
                Button("Ok", role: .cancel) {
                    showDownloadAlert = false
                    cloudEntry = nil
                    localEntry = nil
                    isPopoverPresented = false
                }
            }
            .alert("Couldn't download save", isPresented: $showErrorAlert) {
                Button("Ok", role: .cancel) {
                    showDownloadAlert = false
                    cloudEntry = nil
                    localEntry = nil
                    isPopoverPresented = false
                }
            }
            if cloudEntry != nil {
                GameEntryModal(entry: $cloudEntry)
            }
        }
    }
}
