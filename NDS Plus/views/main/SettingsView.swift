//
//  SettingsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/17/24.
//

import SwiftUI
import UniformTypeIdentifiers
import GoogleSignIn

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var loggedInCloud: Bool
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    @Binding var isSoundOn: Bool
    
    @Binding var bios7Loaded: Bool
    @Binding var bios9Loaded: Bool
    
    @Binding var themeColor: Color
    
    
    @State var isActive = true
    @State private var showColorPickerModal = false
    @State private var showFileBrowser = false
    @State private var path = NavigationPath()
    @State private var currentFile: CurrentFile? = nil
    
    let binType = UTType(filenameExtension: "bin", conformingTo: .data)

    private func storeFile(location: URL, data: Data, currentFile: CurrentFile) {
        switch currentFile {
        case .bios7:
            if let url = URL(string: "bios7.bin", relativeTo: location) {
                try? data.write(to: url)
            }
        case .bios9:
            if let url = URL(string: "bios9.bin", relativeTo: location) {
                try? data.write(to: url)
            }
        
        case .firmware:
            if let url = URL(string: "firmware.bin", relativeTo: location) {
                try? data.write(to: url)
            }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                HStack {
                    Text("NDS+ Settings")
                        .font(.custom("Departure Mono", size: 28))
                        .foregroundColor(Colors.primaryColor)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                VStack {
                    Text("Optional binary files")
                        .padding(.bottom, 20)
                    HStack {
                        Button("Bios 7") {
                            showFileBrowser = true
                            currentFile = CurrentFile.bios7
                        }
                        Spacer()
                        if bios7Loaded {
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
                        if bios9Loaded {
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
      
                    ColorPicker("Skin Theme Color", selection: $themeColor)
                    
                    .padding(.top, 20)
                    .foregroundColor(Colors.accentColor)
                    
                    Toggle(isOn: $isSoundOn) {
                        Text("Start game with sound")
                    }
                    .toggleStyle(.switch)
                    .padding(.top, 20)
                    
                    Button {
                        if let url = URL(string: "https://www.github.com/annethereshewent") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image("Github")
                            .padding(.top, 60)
                    }
                }
                .frame(width: 400, height: 600)
                Spacer()
            }
            .font(.custom("Departure Mono", size: 24))
            .foregroundColor(Colors.primaryColor)
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
            .onChange(of: isSoundOn) {
                let defaults = UserDefaults.standard
                
                defaults.setValue(isSoundOn, forKey: "isSoundOn")
            }
            .onChange(of: themeColor) {
                let defaults = UserDefaults.standard
                
                
                defaults.setValue(themeColor, forKey: "themeColor")
            }
        }
    }
}
