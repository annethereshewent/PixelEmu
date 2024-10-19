//
//  GameEntryModal.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/18/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct GameEntryModal: View {
    @Binding var entry: SaveEntry?
    @Binding var localSaves: [SaveEntry]
    @Binding var cloudSaves: [SaveEntry]
    @Binding var cloudService: CloudService?
    @Binding var loading: Bool
    @Binding var showDownloadAlert: Bool
    @Binding var showUploadAlert: Bool
    @Binding var showErrorAlert: Bool
    
    @State private var isPresented = false
    
    let isCloudSave: Bool
    
    private let savType = UTType(filenameExtension: "sav", conformingTo: .data)
    
    private func downloadCloudSave() {
        // download save for offline use
        let saveName = entry!.game.gameName.replacing(".nds" ,with: ".sav")
        
        loading = true
        Task {
            if let save = await cloudService?.getSave(saveName: saveName) {
                BackupFile.saveCloudFile(saveName: saveName, saveFile: save)
                let saveEntry = SaveEntry(game: entry!.game)
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
    
    private func modifyCloudSave() {
        
    }
    
    private func uploadSave(_ result: Result<URL, any Error>) {
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
                        saveName: entry!.game.gameName.replacing(".nds", with: ".sav"),
                        data: data
                    )
                    showUploadAlert = true
                }
            }
        } catch {
            print(error)
        }
    }
    
    private func deleteSave() {
        
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let entry = entry {
                    Text("Modify save for \(entry.game.gameName)")
                        .foregroundColor(Colors.accentColor)
                }
                if isCloudSave {
                    Button {
                        modifyCloudSave()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                            Text("Modify save")
                        }
                    }
                    .padding(.top, 20)
                
                    Button {
                        downloadCloudSave()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.yellow)
                            Text("Download save")
                        }
                    }
                } else {
                    Button {
                        isPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.green)
                            Text("Uplaod save")
                        }
                    }
                }
                Button {
                    deleteSave()
                } label: {
                    HStack {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                        Text("Delete save")
                    }
                }
            }
            .foregroundColor(.white)
            .padding()
                
        }
        .background(Color(
            red: 0x38 / 0xff,
            green: 0x38 / 0xff,
            blue: 0x38 / 0xff
        ))
        .font(.custom("Departure Mono", size: 20))
        .border(.gray)
        .opacity(0.80)
        .frame(width: 225, height: 225)
        .fileImporter(isPresented: $isPresented, allowedContentTypes: [savType!]) { result in
            uploadSave(result)
        }
    }
}
