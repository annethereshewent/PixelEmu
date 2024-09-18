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
    
    @State private var showFileBrowser = false
    
    @State private var currentFile: CurrentFile? = nil
    
    let binType = UTType(filenameExtension: "bin", conformingTo: .data)

    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.title)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            List {
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
                            case .bios7:
                                bios7Data = data
                            case .bios9:
                                bios9Data = data
                            case .firmware:
                                firmwareData = data
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
