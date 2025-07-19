//
//  SettingsView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/17/24.
//

import SwiftUI
import UniformTypeIdentifiers
import GoogleSignIn
import DSEmulatorMobile
import GBAEmulatorMobile
import GameController

struct SettingsView: View {
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var gbaBiosData: Data?
    @Binding var loggedInCloud: Bool
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    @Binding var isSoundOn: Bool

    @Binding var bios7Loaded: Bool
    @Binding var bios9Loaded: Bool
    @Binding var gbaBiosLoaded: Bool

    @Binding var themeColor: Color

    @Binding var gameController: GameController?

    @Binding var buttonDict: [ButtonMapping:PressedButton]

    @State private var isActive = true
    @State private var showColorPickerModal = false
    @State private var showFileBrowser = false
    @State private var currentFile: CurrentFile? = nil
    @State private var isMappingsPresented = false

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
        case .gba:
            if let url = URL(string: "gba_bios.bin", relativeTo: location) {
                try? data.write(to: url)
            }
        }
    }

    var body: some View {
        VStack {
            Text("NDS+ Settings")
                .font(.custom("Departure Mono", size: 24))
                .foregroundColor(Colors.primaryColor)
            ScrollView {
                Text("Optional NDS binaries")
                    .padding(.bottom, 20)
                HStack {
                    Button("Bios 7") {
                        showFileBrowser = true
                        currentFile = CurrentFile.bios7
                    }
                    .padding(.leading, 20)
                    Spacer()
                    if bios7Loaded {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .padding(.trailing, 20)
                    }
                }
                HStack {
                    Button("Bios 9") {
                        showFileBrowser = true
                        currentFile = CurrentFile.bios9
                    }
                    .padding(.leading, 20)
                    Spacer()
                    if bios9Loaded {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .padding(.trailing, 20)
                    }
                }

                HStack {
                    Button("Firmware") {
                        showFileBrowser = true
                        currentFile = CurrentFile.firmware
                    }
                    .padding(.leading, 20)
                    Spacer()
                    if firmwareData != nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .padding(.trailing, 20)
                    }
                }

                Text("Optional GBA binary")
                    .padding(.bottom, 20)
                    .padding(.top, 20)

                HStack {
                    Button("Bios") {
                        showFileBrowser = true
                        currentFile = .gba
                    }
                    .padding(.leading, 20)
                    Spacer()
                    if gbaBiosLoaded {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .padding(.trailing, 20)
                    }
                }

                HStack {
                    Spacer()
                    ColorPicker("Change theme color", selection: $themeColor)
                    Spacer()
                }
                .padding(.top, 20)
                .foregroundColor(themeColor)
                HStack {
                    Spacer()
                    Toggle(isOn: $isSoundOn) {
                        Text("Start game with sound")
                    }
                    Spacer()
                }
                .toggleStyle(.switch)

                if gameController?.controller?.extendedGamepad != nil {
                    Button {
                        isMappingsPresented = true
                    } label: {
                        HStack {
                            Text("Change controller mappings")
                                .padding(.leading, 9)
                            Spacer()
                            Image(systemName: "gamecontroller.fill")
                                .resizable()
                                .foregroundColor(themeColor)
                                .padding(.trailing, 20)
                                .scaledToFill()
                                .frame(width: 50, height: 25)
                        }
                    }
                }

                Button {
                    if let url = URL(string: "https://www.github.com/annethereshewent") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image("Github")
                        .padding(.top, 60)
                        .foregroundColor(themeColor)
                }
            }
            Spacer()
        }
        .onAppear() {
            gameController = GameController() { _ in }
        }
        .font(.custom("Departure Mono", size: 20))
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
                            let defaults = UserDefaults.standard
                            switch file {
                                // store the file in application support
                            case .bios7:
                                bios7Data = data
                                bios7Loaded = true

                                defaults.set(bios7Loaded, forKey: "bios7Loaded")
                            case .bios9:
                                bios9Data = data
                                bios9Loaded = true

                                defaults.set(bios9Loaded, forKey: "bios9Loaded")
                            case .firmware:
                                firmwareData = data
                            case .gba:
                                gbaBiosData = data
                                gbaBiosLoaded = true

                                defaults.set(gbaBiosLoaded, forKey: "gbaBiosLoaded")
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

        }
        .sheet(isPresented: $isMappingsPresented) {
            ControllerMappingsView(
                themeColor: $themeColor,
                isPresented: $isMappingsPresented,
                gameController: $gameController,
                buttonDict: $buttonDict
            )
        }
        .onChange(of: isSoundOn) {
            let defaults = UserDefaults.standard

            defaults.setValue(isSoundOn, forKey: "isSoundOn")
        }
    }
}
