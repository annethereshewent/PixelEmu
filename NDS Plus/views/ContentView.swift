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
    
    @State private var bios7Loaded: Bool = false
    @State private var bios9Loaded: Bool = false
    
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
    @State private var game: Game? = nil
    
    @State private var shouldUpdateGame = false
    @State private var currentView: CurrentView = .library
    @State private var isSoundOn: Bool = true
    @AppStorage("themeColor") var themeColor: Color = Colors.accentColor

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
                if let fileUrl = URL(string: "bios7.bin", relativeTo: applicationUrl) {
                    if let data = try? Data(contentsOf: fileUrl) {
                        _bios7Data = State(initialValue: data)
                        _bios7Loaded = State(initialValue: true)
                    } else {
                        let filePath = Bundle.main.path(forResource: "drastic_bios_arm7", ofType: "bin")!
                        do {
                            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                            _bios7Data = State(initialValue: data)
                        } catch {
                            print(error)
                        }
                    }
                }
                
            case .bios9:
                if let fileUrl = URL(string: "bios9.bin", relativeTo: applicationUrl) {
                    if let data = try? Data(contentsOf: fileUrl) {
                        _bios9Data = State(initialValue: data)
                        _bios9Loaded = State(initialValue: true)
                    } else {
                        let filePath = Bundle.main.path(forResource: "drastic_bios_arm9", ofType: "bin")!
                        do {
                            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                            _bios9Data = State(initialValue: data)
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
            ZStack {
                Color(Colors.mainBackgroundColor)
                    .ignoresSafeArea()
                VStack {
                    switch currentView {
                    case .library:
                        LibraryView(
                            romData: $romData,
                            bios7Data: $bios7Data,
                            bios9Data: $bios9Data,
                            firmwareData: $firmwareData,
                            isRunning: $isRunning,
                            workItem: $workItem,
                            emulator: $emulator,
                            gameUrl: $gameUrl,
                            path: $path,
                            game: $game
                        )
                    case .importGames:
                        ImportGamesView(
                            romData: $romData,
                            shouldUpdateGame: $shouldUpdateGame,
                            bios7Data: $bios7Data,
                            bios9Data: $bios9Data,
                            path: $path,
                            gameUrl: $gameUrl
                        )
                    case .saveManagement:
                        SaveManagementView(
                            user: $user,
                            cloudService: $cloudService
                        )
                    case .settings:
                        SettingsView(
                            bios7Data: $bios7Data,
                            bios9Data: $bios9Data,
                            firmwareData: $firmwareData,
                            loggedInCloud: $loggedInCloud,
                            user: $user,
                            cloudService: $cloudService,
                            isSoundOn: $isSoundOn,
                            bios7Loaded: $bios7Loaded,
                            bios9Loaded: $bios9Loaded,
                            themeColor: $themeColor
                        )
                    }
                    Spacer()
                    NavigationBarView(currentView: $currentView)
                }
            }
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
                        cloudService: $cloudService,
                        game: $game,
                        shouldUpdateGame: $shouldUpdateGame,
                        isSoundOn: $isSoundOn,
                        themeColor: $themeColor
                    )
                }
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
        .onAppear {
            let defaults = UserDefaults.standard
            
            if let isSoundOn = defaults.object(forKey: "isSoundOn") as? Bool {
                self.isSoundOn = isSoundOn
            }
            
            bios7Loaded = defaults.bool(forKey: "bios7Loaded")
            bios9Loaded = defaults.bool(forKey: "bios9Loaded")
            
            if let themeColor = defaults.value(forKey: "themeColor") as? Color {
                self.themeColor = themeColor
            }
            
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
