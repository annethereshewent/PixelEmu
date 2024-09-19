//
//  SettingsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/17/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var loggedInCloud: Bool
    
    @State private var showFileBrowser = false
    
    @State private var currentFile: CurrentFile? = nil
    
    let binType = UTType(filenameExtension: "bin", conformingTo: .data)
    

    private func storeFile(location: URL, data: Data, currentFile: CurrentFile) {
        switch currentFile {
        case .bios7:
            if let url = URL(string: "bios7.bin", relativeTo: location) {
                if let success = try? data.write(to: url) {
                    print(success)
                }
            }
        case .bios9:
            if let url = URL(string: "bios9.bin", relativeTo: location) {
                if let success = try? data.write(to: url) {
                    print(success)
                }
            }
        
        case .firmware:
            if let url = URL(string: "firmware.bin", relativeTo: location) {
                if let success = try? data.write(to: url) {
                    print(success)
                }
            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.title)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            List {
                Section(header: Text("Required binary files")) {
                    HStack {
                        Button("Bios 7") {
                            showFileBrowser = true
                            currentFile = CurrentFile.bios7
                        }
                        Spacer()
                        if bios7Data != nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                    HStack {
                        Button("Bios 9") {
                            showFileBrowser = true
                            currentFile = CurrentFile.bios9
                        }
                        Spacer()
                        if bios9Data != nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                   
                    HStack {
                        Button("Firmware") {
                            showFileBrowser = true
                            currentFile = CurrentFile.firmware
                        }
                        Spacer()
                        if firmwareData != nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                }
                Section(header: Text("Miscellaneous")) {
                    HStack {
                        Button("Google saves") {
                            
                        }
                        Spacer()
                        if loggedInCloud {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                        }
                    }
                }
                
            }
            Spacer()
            Button("Dismiss") {
                dismiss()
            }
        }
        .fileImporter(
            isPresented: $showFileBrowser,
            allowedContentTypes: [binType.unsafelyUnwrapped]
        ) { result in
            if let url = try? result.get() {
                if url.startAccessingSecurityScopedResource() {
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    if let data = try? Data(contentsOf: url) {
                        if let file = currentFile {
                            switch file {
                            // store the file in application support
                            case .bios7:
                                bios7Data = data
                            case .bios9:
                                bios9Data = data
                            case .firmware:
                                firmwareData = data
                            }
                           if let location = try? FileManager.default.url(
                                for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true
                           ) {
                               self.storeFile(location: location, data: data, currentFile: file)
                           }
                        }
                    }
                }
               
            }
            
            if bios7Data != nil && bios9Data != nil && firmwareData != nil {
                dismiss()
            }
            
        }
    }
}
