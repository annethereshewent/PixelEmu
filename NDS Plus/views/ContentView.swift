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

    @State private var currentView: CurrentView = .library
    @State private var isSoundOn: Bool = true
    @State var audioManager: AudioManager? = nil
    
    @State private var gameController: GameController? = GameController(closure:  { _ in })
    @State private var topImage: CGImage?
    @State private var bottomImage: CGImage?
    @State private var gameName = ""
    @State private var backupFile: BackupFile? = nil

    @State private var buttonEventDict: [ButtonMapping:[ButtonEvent]] = getDefaultMappings()

    @State private var isMenuPresented = false

    @AppStorage("themeColor") var themeColor: Color = Colors.accentColor

    init() {
        bios7Data = nil
        bios9Data = nil
        firmwareData = nil
        
        self.checkForBinaries(currentFile: CurrentFile.bios7)
        self.checkForBinaries(currentFile: CurrentFile.bios9)
        self.checkForBinaries(currentFile: CurrentFile.firmware)
    }

    static func getDefaultMappings() -> [ButtonMapping:[ButtonEvent]] {
        return [
            .a: [.ButtonB],
            .b: [.ButtonA],
            .x: [.ButtonY],
            .y: [.ButtonX],
            .leftShoulder: [.ButtonL],
            .rightShoulder: [.ButtonR],
            .menu: [.Start],
            .options: [.Select],
            .up: [.Up],
            .down: [.Down],
            .left: [.Left],
            .right: [.Right],
            .leftThumbstick: [.QuickSave],
            .rightThumbstick: [.QuickLoad],
            .home: [.ButtonHome],
            .leftTrigger: [.ControlStick]
        ]
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
                            game: $game,
                            themeColor: $themeColor
                        )
                    case .importGames:
                        ImportGamesView(
                            romData: $romData,
                            bios7Data: $bios7Data,
                            bios9Data: $bios9Data,
                            path: $path,
                            gameUrl: $gameUrl,
                            workItem: $workItem,
                            isRunning: $isRunning,
                            emulator: $emulator,
                            gameName: $gameName,
                            currentView: $currentView,
                            themeColor: $themeColor
                        )
                    case .saveManagement:
                        SaveManagementView(
                            user: $user,
                            cloudService: $cloudService,
                            themeColor: $themeColor
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
                            themeColor: $themeColor,
                            gameController: $gameController,
                            buttonEventDict: $buttonEventDict
                        )
                    }
                    Spacer()
                    NavigationBarView(currentView: $currentView, themeColor: $themeColor)
                }
            }
            .navigationDestination(for: String.self) { view in
                if view == "GameView" {
                    GameView(
                        isMenuPresented: $isMenuPresented,
                        emulator: $emulator,
                        bios7Data: $bios7Data,
                        bios9Data: $bios9Data,
                        firmwareData: $firmwareData,
                        romData: $romData,
                        gameUrl: $gameUrl,
                        user: $user,
                        cloudService: $cloudService,
                        game: $game,
                        isSoundOn: $isSoundOn,
                        themeColor: $themeColor,
                        gameName: $gameName,
                        backupFile: $backupFile,
                        gameController: $gameController,
                        audioManager: $audioManager,
                        isRunning: $isRunning,
                        workItem: $workItem,
                        topImage: $topImage,
                        bottomImage: $bottomImage,
                        buttonEventDict: $buttonEventDict
                    )
                }
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = false
            let defaults = UserDefaults.standard
            
            if let isSoundOn = defaults.object(forKey: "isSoundOn") as? Bool {
                self.isSoundOn = isSoundOn
            }
            
            bios7Loaded = defaults.bool(forKey: "bios7Loaded")
            bios9Loaded = defaults.bool(forKey: "bios9Loaded")
            
            if let themeColor = defaults.value(forKey: "themeColor") as? Color {
                self.themeColor = themeColor
            }

            do {
                if let data = defaults.object(forKey: "buttonMappings") as? Data {
                    let decodedButtonMappings = try JSONDecoder()
                        .decode([ButtonMapping:[String]].self, from: data)

                    buttonEventDict = Dictionary(
                        uniqueKeysWithValues: decodedButtonMappings.map{ key, values in
                            (key, values.map{ ButtonEvent.descriptionToEnum($0) })
                        }
                    )
                }
            } catch {
                print(error)
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
