//
//  GameEntryModal.swift
//  PixelEmu
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
    @Binding var showDeleteAlert: Bool
    @Binding var showDeleteDialog: Bool
    @Binding var deleteAction: () -> Void

    @Binding var themeColor: Color

    let isCloudSave: Bool

    @State private var isPresented = false

    private let savType = UTType(filenameExtension: "sav", conformingTo: .data)

    private func deleteSave(saveType: SaveType) {
        if let entry = entry {
            showDeleteDialog = true
            if !isCloudSave {
                let saveName = replaceExtension()
                let entryCopy = entry
                deleteAction = {
                    if BackupFile.deleteSave(saveName: saveName) {
                        showDeleteAlert = true
                        if let index = localSaves.firstIndex(of: entryCopy) {
                            localSaves.remove(at: index)
                        }
                    }
                }
            } else {
                let saveName = replaceExtension()
                let entryCopy = entry
                deleteAction = {
                    loading = true
                    Task {
                        let success = await cloudService?.deleteSave(saveName: saveName, saveType: saveType) ?? false

                        loading = false
                        if success {
                            if let index = cloudSaves.firstIndex(of: entryCopy) {
                                cloudSaves.remove(at: index)
                            }

                            showDeleteAlert = true
                        }
                    }
                }
            }
        }

        entry = nil
    }

    private func getExtension() -> String {
        return entry != nil ? String(entry!.game.gameName[entry!.game.gameName.lastIndex(of: ".")!...]) : ""
    }

    private func replaceExtension() -> String {
        return entry != nil ? entry!.game.gameName.replacing(getExtension(), with: ".sav") : ""
    }

    private func downloadCloudSave(saveType: SaveType) {
        // download save for offline use
        let saveName = replaceExtension()

        loading = true
        Task {
            if let save = await cloudService?.getFile(fileName: saveName, saveType: saveType), let entry = entry {
                BackupFile.saveCloudFile(saveName: saveName, saveFile: save)
                let saveEntry = SaveEntry(game: entry.game)
                if !localSaves.contains(saveEntry) {
                    localSaves.append(saveEntry)
                }
                showDownloadAlert = true
            } else {
                showErrorAlert = true
            }
            entry = nil
            loading = false
        }
    }

    private func uploadSave(saveType: SaveType) {
        // upload local entry to cloud
        loading = true
        Task {
            if let entry = entry {
                let saveName = replaceExtension()
                if let saveData = BackupFile.getSave(saveName: saveName) {
                    await self.cloudService?.uploadFile(fileName: saveName, data: saveData, saveType: saveType)
                    loading = false
                    if cloudSaves.firstIndex(of: entry) == nil {
                        cloudSaves.insert(SaveEntry(game: entry.game), at: 0)
                    }

                    showUploadAlert = true
                }
            }
            entry = nil
        }
    }

    private func modifyCloudSave(_ result: Result<URL, any Error>, saveType: SaveType) {
        do {
            let url = try result.get()

            if url.startAccessingSecurityScopedResource() {
                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                let data = try Data(contentsOf: url)
                loading = true
                Task {
                    await cloudService?.uploadFile(
                        fileName: replaceExtension(),
                        data: data,
                        saveType: saveType
                    )
                    showUploadAlert = true

                    loading = false
                    entry = nil
                }
            }
        } catch {
            print(error)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let entry = entry {
                    Text("Modify save for \(entry.game.gameName)")
                        .foregroundColor(themeColor)
                }
                if isCloudSave {
                    Button {
                        isPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                            Text("Modify save")
                        }
                    }
                    .padding(.top, 20)

                    Button {
                        if let entry = entry {
                            switch entry.game.type {
                            case .gba: downloadCloudSave(saveType: .gba)
                            case .nds: downloadCloudSave(saveType: .nds)
                            case .gbc: downloadCloudSave(saveType: .gbc)
                            }
                        }

                    } label: {
                        HStack {
                            Image(systemName: "arrow.down")
                                .foregroundColor(.yellow)
                            Text("Download save")
                        }
                    }
                } else {
                    Button {
                        if let entry = entry {
                            switch entry.game.type {
                            case .gba: uploadSave(saveType: .gba)
                            case .nds: uploadSave(saveType: .nds)
                            case .gbc: uploadSave(saveType: .gbc)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up")
                                .foregroundColor(.green)
                            Text("Upload save")
                        }
                    }
                }
                Button {
                    if let entry = entry {
                        switch entry.game.type {
                        case .gba: deleteSave(saveType: .gba)
                        case .nds: deleteSave(saveType: .nds)
                        case .gbc: deleteSave(saveType: .gbc)
                        }
                    }
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
        .background(Colors.backgroundColor)
        .font(.custom("Departure Mono", size: 20))
        .border(.gray)
        .opacity(0.80)
        .frame(width: 225, height: 225)
        .fileImporter(isPresented: $isPresented, allowedContentTypes: [savType!]) { result in
            if let entry = entry {
                switch entry.game.type {
                case .nds: modifyCloudSave(result, saveType: .nds)
                case .gba: modifyCloudSave(result, saveType: .gba)
                case .gbc: modifyCloudSave(result, saveType: .gbc)
                }
            }
        }
    }
}
