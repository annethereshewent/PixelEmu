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

    private func downloadCloudGbaSave() {
        // download save for offline use
        let saveName = getGbaSaveName()

        loading = true
        Task {
            if let save = await cloudService?.getSave(saveName: saveName, saveType: .gba) {
                BackupFile.saveCloudFile(saveName: saveName, saveFile: save)
                let saveEntry = SaveEntry(game: entry!.game)
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

    private func uploadGbaSave() {
        // upload local entry to cloud
        loading = true
        Task {
            if let entry = entry {
                let saveName = getGbaSaveName()

                if let saveData = BackupFile.getSave(saveName: saveName) {
                    await self.cloudService?.uploadSave(saveName: saveName, data: saveData, saveType: .gba)
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

    private func modifyGbaCloudSave(_ result: Result<URL, any Error>) {
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
                        saveName: getGbaSaveName(),
                        data: data,
                        saveType: .gba
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

    private func getGbaSaveName() -> String {
        if entry!.game.gameName.hasSuffix(".GBA") {
            return entry!.game.gameName.replacing(".GBA", with: ".sav")
        }

        return entry!.game.gameName.replacing(".gba", with: ".sav")
    }

    private func deleteGbaSave() {

        if let entry = entry {
            let entryCopy = entry.copy()
            showDeleteDialog = true

            let saveName = getGbaSaveName()

            if !isCloudSave {
                deleteAction = {
                    if BackupFile.deleteSave(saveName: saveName) {
                        showDeleteAlert = true
                        if let index = localSaves.firstIndex(of: entryCopy) {
                            localSaves.remove(at: index)
                        }
                    }
                }
            } else {
                deleteAction = {
                    loading = true
                    Task {
                        let success = await cloudService?.deleteSave(saveName: saveName, saveType: .gba) ?? false

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

    private func downloadCloudSave() {
        // download save for offline use
        let saveName = entry!.game.gameName.replacing(".nds" ,with: ".sav")

        loading = true
        Task {
            if let save = await cloudService?.getSave(saveName: saveName, saveType: .nds) {
                BackupFile.saveCloudFile(saveName: saveName, saveFile: save)
                let saveEntry = SaveEntry(game: entry!.game)
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

    private func uploadSave() {
        // upload local entry to cloud
        loading = true
        Task {
            if let entry = entry {
                let saveName = entry.game.gameName.replacing(".nds", with: ".sav")
                if let saveData = BackupFile.getSave(saveName: saveName) {
                    await self.cloudService?.uploadSave(saveName: saveName, data: saveData, saveType: .nds)
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

    private func modifyCloudSave(_ result: Result<URL, any Error>) {
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
                        data: data,
                        saveType: .nds
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

    private func deleteSave() {

        if let entry = entry {
            let entryCopy = entry.copy()
            showDeleteDialog = true
            if !isCloudSave {
                deleteAction = {
                    if BackupFile.deleteSave(saveName: entryCopy.game.gameName.replacing(".nds", with: ".sav")) {
                        showDeleteAlert = true
                        if let index = localSaves.firstIndex(of: entryCopy) {
                            localSaves.remove(at: index)
                        }
                    }
                }
            } else {
                deleteAction = {
                    let saveName = entryCopy.game.gameName.replacing(".nds", with: ".sav")

                    loading = true
                    Task {
                        let success = await cloudService?.deleteSave(saveName: saveName, saveType: .nds) ?? false

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
                        switch entry!.game.type {
                        case .gba: downloadCloudGbaSave()
                        case .nds: downloadCloudSave()
                        case .gbc: break
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
                        switch entry!.game.type {
                        case .gba: uploadGbaSave()
                        case .nds: uploadSave()
                        case .gbc: break
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
                    switch entry!.game.type {
                    case .gba: deleteGbaSave()
                    case .nds: deleteSave()
                    case .gbc: break
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
            modifyCloudSave(result)
        }
    }
}
