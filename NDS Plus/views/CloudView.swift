//
//  CloudView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/24/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import SwiftData
import UniformTypeIdentifiers

struct CloudView: View {
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    
    @State private var saveEntries: [SaveEntry] = []
    @State private var currentEntry: SaveEntry? = nil
    @State private var isPresented = false
    @State private var showDialog = false
    @State private var loading = false
    
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
        }
    }
    
    var body: some View {
        VStack {
            Text("Cloud saves")
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
                }
            }
            List {
                Section("Save management") {
                    ForEach(saveEntries, id: \.game.gameName) { saveEntry in
                        GameEntryView(game: saveEntry.game) {
                            currentEntry = saveEntry
                        }
                        if currentEntry == saveEntry {
                            Section {
                                HStack {
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.green)
                                    Button("Upload Save") {
                                        isPresented = true
                                    }
                                }
                                HStack {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.white)
                                    Button("Download Save") {
                                        // download save to local device or icloud
                                        
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
                    
                    Task {
                        await cloudService?.uploadSave(
                            saveName: currentEntry!.game.gameName.replacing(".nds", with: ".sav"),
                            data: data
                        )
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
        }
        .confirmationDialog("Confirm delete", isPresented: $showDialog) {
            Button("Delete save?") {
                let saveName = currentEntry!.game.gameName.replacing(".nds", with: ".sav")
                
                loading = true
                Task {
                    let success = await cloudService?.deleteSave(saveName: saveName) ?? false
                    
                    loading = false
                    if success {
                        if let index = saveEntries.firstIndex(of: currentEntry!) {
                            saveEntries.remove(at: index)
                        }
                        
                        currentEntry = nil
                    }
                }
            }
        }
    }
}
