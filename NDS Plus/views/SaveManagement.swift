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
    @State private var showDialog = false
    @State private var loading = false
    @State private var showDownloadAlert = false
    @State private var showDeleteAlert = false
    @State private var showUploadAlert = false
    
    @Query var games: [Game]
    
    let savType = UTType(filenameExtension: "sav", conformingTo: .data)
    
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
        VStack {
            Text("Save Management")
                .font(.title)
            if user == nil {
                HStack {
                    GoogleSignInButton(
                        scheme: .dark,
                        style: .icon,
                        action: handleSignInButton
                    )
                    Text("Sign in")
                }
            } else {
                Button("Sign Out of Google") {
                    GIDSignIn.sharedInstance.signOut()
                    user = nil
                    saveEntries = []
                    cloudService = nil
                    cloudEntry = nil
                }
            }
            List {
                Section("Cloud Saves") {
                    ForEach(saveEntries, id: \.game.gameName) { saveEntry in
                        GameEntryView(game: saveEntry.game) {
                            if cloudEntry == saveEntry {
                                cloudEntry = nil
                            } else {
                                cloudEntry = saveEntry
                            }
                        }
                        if cloudEntry == saveEntry {
                            Section {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.green)
                                    Button("Modify Save") {
                                        isPresented = true
                                    }
                                }
                                HStack {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.white)
                                    Button("Download Save") {
                                        // download save for offline use
                                        let saveName = cloudEntry!.game.gameName.replacing(".nds" ,with: ".sav")
                                        
                                        loading = true
                                        Task {
                                            if let save = await cloudService?.getSave(saveName: saveName) {
                                                BackupFile.saveCloudFile(saveName: saveName, saveFile: save)
                                            }
                                            loading = false
                                            showDownloadAlert = true
                                        }
                                    }
                                }
                                HStack {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                    Button("Delete Save") {
                                        showDialog = true
                                    }
                                }
                               
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
                Section("Local saves") {
                    ForEach(localSaves, id: \.game.gameName) { saveEntry in
                        GameEntryView(game: saveEntry.game) {
                            if localEntry == saveEntry {
                                localEntry = nil
                            } else {
                                localEntry = saveEntry
                            }
                        }
                        if localEntry == saveEntry {
                            Section {
                                HStack {
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.green)
                                    Button("Upload save") {
                                        let saveName = localEntry!.game.gameName.replacing(".nds", with: ".sav")
                                        if let saveData = BackupFile.getSave(saveName: saveName) {
                                            loading = true
                                            Task {
                                                await self.cloudService?.uploadSave(saveName: saveName, data: saveData)
                                                loading = false
                                                showUploadAlert = true
                                            }
                                        }
                                    }
                                }
                                HStack {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                    Button("Delete save") {
                                        
                                    }
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
                    
            }
            .alert("Successfully uploaded save", isPresented: $showUploadAlert) {
                Button("Ok", role: .cancel) {
                    showUploadAlert = false
                    cloudEntry = nil
                    localEntry = nil
                }
            }
            .alert("Successfully deleted save", isPresented: $showDeleteAlert) {
                Button("Ok", role: .cancel) {
                    showDeleteAlert = false
                    cloudEntry = nil
                    localEntry = nil
                }
            }
            .alert("Save downloaded successfully", isPresented: $showDownloadAlert) {
                Button("Ok", role: .cancel) {
                    showDownloadAlert = false
                    cloudEntry = nil
                    localEntry = nil
                }
            }
            if loading {
                ProgressView()
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
                Task {
                    if let saveEntries = await cloudService?.getSaves(games: games) {
                        self.saveEntries = saveEntries
                    }
                }
            }
            // get any local saves
            localSaves = BackupFile.getLocalSaves(games: games)
        }
        .confirmationDialog("Confirm delete", isPresented: $showDialog) {
            Button("Delete save?", role: .destructive) {
                let saveName = cloudEntry!.game.gameName.replacing(".nds", with: ".sav") 
                
                loading = true
                Task {
                    let success = await cloudService?.deleteSave(saveName: saveName) ?? false
                    
                    loading = false
                    if success {
                        if let index = saveEntries.firstIndex(of: cloudEntry!) {
                            saveEntries.remove(at: index)
                        }
                        
                        showDeleteAlert = true
                    }
                }
            }
        }
    }
}
