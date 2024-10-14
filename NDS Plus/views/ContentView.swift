//
//  ContentView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI
import UniformTypeIdentifiers
import DSEmulatorMobile
import GoogleSignIn

struct ContentView: View {
    @State private var showSettings = false
    @State private var showRomDialog = false

    @State private var bios7Data: Data?
    @State private var bios9Data: Data?
    @State private var firmwareData: Data?
    @State private var romData: Data? = nil
    
    @State private var workItem: DispatchWorkItem? = nil
    @State private var isRunning = false
    @State private var loggedInCloud = false
    
    @State private var path = NavigationPath()
    @State private var emulator: MobileEmulator? = nil
    @State private var gameUrl: URL? = nil
    
    @State private var user: GIDGoogleUser? = nil
    @State private var cloudService: CloudService? = nil

    init() {
        bios7Data = nil
        bios9Data = nil
        firmwareData = nil
        
        self.checkForBinaries(currentFile: CurrentFile.bios7)
        self.checkForBinaries(currentFile: CurrentFile.bios9)
        self.checkForBinaries(currentFile: CurrentFile.firmware)
    }
    
    mutating func checkForBinaries(currentFile: CurrentFile) {
        if let applicationUrl = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            switch currentFile {
            case .bios7:
                print("checking for bios7")
                if let fileUrl = URL(string: "bios7.bin", relativeTo: applicationUrl) {
                    print("in here dawg!!!!!!")
                    if let data = try? Data(contentsOf: fileUrl) {
                        print("wut")
                        _bios7Data = State(initialValue: data)
                    } else {
                        print("now here")
                        let filePath = Bundle.main.path(forResource: "drastic_bios_arm7", ofType: "bin")!
                        do {
                            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                            _bios7Data = State(initialValue: data)
                            
                            print("found bios7 data!")
                        } catch {
                            print(error)
                        }
                    }
                }
                
            case .bios9:
                if let fileUrl = URL(string: "bios9.bin", relativeTo: applicationUrl) {
                    if let data = try? Data(contentsOf: fileUrl) {
                        _bios9Data = State(initialValue: data)
                    } else {
                        let filePath = Bundle.main.path(forResource: "drastic_bios_arm9", ofType: "bin")!
                        do {
                            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                            _bios9Data = State(initialValue: data)
                            
                            print("found bios9 data!")
                        } catch {
                            print(error)
                        }
                    }
                }
            case .firmware:
                if let fileUrl = URL(string: "firmware.bin", relativeTo: applicationUrl) {
                    if let data = try? Data(contentsOf: fileUrl) {
                        _firmwareData = State(initialValue: data)
                    }
                }
            }
        }
    }
        
    let ndsType = UTType(filenameExtension: "nds", conformingTo: .data)
    
    var buttonDisabled: Bool {
        return bios7Data == nil || bios9Data == nil || firmwareData == nil
    }
    
    var buttonColor: Color {
        switch colorScheme {
        case .dark:
            return buttonDisabled ? Color.secondary : Color.white
        case .light:
            return buttonDisabled ? Color.gray : Color.cyan
        default:
            return buttonDisabled ? Color.gray : Color.cyan
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                HStack {
                    Spacer()
                    Button("", systemImage: "gear") {
                        showSettings.toggle()
                    }
                    .font(.title)
                    .frame(alignment: .trailing)
                    .foregroundColor(.indigo)
                    .padding(.trailing)
                    
                }
                .sheet(isPresented: $showSettings) {
                    VStack {
                        SettingsView(
                            bios7Data: $bios7Data,
                            bios9Data: $bios9Data,
                            firmwareData: $firmwareData,
                            loggedInCloud: $loggedInCloud,
                            user: $user,
                            cloudService: $cloudService
                        )
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
                HStack {
                    Text("NDS Plus")
                        .font(.largeTitle)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(alignment: .center)
                }
                Spacer()
                GamesListView(
                    romData: $romData,
                    bios7Data: $bios7Data,
                    bios9Data: $bios9Data,
                    firmwareData: $firmwareData,
                    isRunning: $isRunning,
                    workItem: $workItem,
                    emulator: $emulator,
                    gameUrl: $gameUrl,
                    path: $path
                )
                HStack {
                    Button("Load Game", systemImage: "square.and.arrow.up.circle") {
                        emulator = nil
                        workItem?.cancel()
                        isRunning = false
                        
                        workItem = nil
                        
                        showRomDialog = true
                    }
                    .font(.title)
                }
            }
            .fileImporter(
                isPresented: $showRomDialog,
                allowedContentTypes: [ndsType.unsafelyUnwrapped]
            ) { result in
                if let url = try? result.get() {
                    if url.startAccessingSecurityScopedResource() {
                        defer {
                            url.stopAccessingSecurityScopedResource()
                        }
                        if let data = try? Data(contentsOf: url) {
                            romData = data
                            
                            if bios7Data != nil && bios9Data != nil {
                                gameUrl = url
                                path.append("GameView")
                            }
                        }
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color.white )
            .navigationDestination(for: String.self) { view in
                if view == "GameView" {
                    GameView(
                        emulator: $emulator,
                        bios7Data: $bios7Data,
                        bios9Data: $bios9Data,
                        firmwareData: $firmwareData,
                        romData: $romData,
                        gameUrl: $gameUrl,
                        user: $user,
                        cloudService: $cloudService
                    )
                }
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
        .onAppear {
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let signedInUser = user {
                    self.user = signedInUser
                    
                    self.user?.refreshTokensIfNeeded { user, error in
                        guard error == nil else { return }
                        guard let user = user else { return }
                        
                        self.user = user
                        
                        self.cloudService = CloudService(user: self.user!)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self, content: ContentView().preferredColorScheme)
    }
}

#Preview {
    ContentView()
}
