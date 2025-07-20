//
//  ContentView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI
import UniformTypeIdentifiers
import DSEmulatorMobile
import GBAEmulatorMobile
import GBCEmulatorMobile
import GoogleSignIn

struct ContentView: View {
    @State private var showSettings = false
    @State private var showRomDialog = false

    @State private var bios7Data: Data?
    @State private var bios9Data: Data?
    @State private var gbaBiosData: Data?

    @State private var bios7Loaded = false
    @State private var bios9Loaded = false
    @State private var gbaBiosLoaded = false

    @State private var firmwareData: Data?
    @State private var romData: Data? = nil

    @State private var workItem: DispatchWorkItem? = nil
    @State private var isRunning = false
    @State private var loggedInCloud = false

    @State private var path = NavigationPath()
    @State private var emulator: (any EmulatorWrapper)? = nil
    @State private var gbaEmulatorCopy: (any EmulatorWrapper)? = nil
    @State private var gameUrl: URL? = nil

    @State private var user: GIDGoogleUser? = nil
    @State private var cloudService: CloudService? = nil
    @State private var game: (any Playable)? = nil
    @State private var gbaGame: (any Playable)? = nil
    @State private var gbcGame: (any Playable)? = nil

    @State private var currentView: CurrentView = .library
    @State private var isSoundOn: Bool = true
    @State private var audioManager: AudioManager? = nil

    @State private var gameController: GameController? = nil
    @State private var topImage: CGImage?
    @State private var bottomImage: CGImage?

    @State private var gbaImage: CGImage? = nil
    @State private var gbcImage: CGImage? = nil

    @State private var gameName = ""
    @State private var backupFile: BackupFile? = nil
    @State private var gbBackupFile: GBBackupFile? = nil

    @State private var buttonDict: [ButtonMapping:PressedButton] = getDefaultMappings()

    @State private var isMenuPresented = false

    @State private var loading = false

    @State private var isPaused = false

    @State private var currentLibrary = "nds"

    @State private var gbcEmulator: GBCMobileEmulator? = nil

    @AppStorage("themeColor") var themeColor: Color = Colors.accentColor

    init() {
        bios7Data = nil
        bios9Data = nil
        firmwareData = nil

        self.checkForBinaries(currentFile: .bios7)
        self.checkForBinaries(currentFile: .bios9)
        self.checkForBinaries(currentFile: .firmware)
        self.checkForBinaries(currentFile: .gba)
    }

    static func getDefaultMappings() -> [ButtonMapping:PressedButton] {
        return [
            .cross: .ButtonB,
            .circle: .ButtonA,
            .square: .ButtonY,
            .triangle: .ButtonX,
            .l1: .ButtonL,
            .r1: .ButtonR,
            .start: .Start,
            .select: .Select,
            .up: .Up,
            .down: .Down,
            .left: .Left,
            .right: .Right,
            .leftStick: .QuickSave,
            .rightStick: .QuickLoad,
            .l2: .ControlStickMode
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
            case .gba:
                if let fileUrl = URL(string: "gba_bios.bin", relativeTo: applicationUrl) {
                    if let data = try? Data(contentsOf: fileUrl) {
                        _gbaBiosData = State(initialValue: data)
                        _gbaBiosLoaded = State(initialValue: true)
                    } else {
                        let filePath = Bundle.main.path(forResource: "gba_bios", ofType: "bin")!
                        do {
                            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                            _gbaBiosData = State(initialValue: data)
                        } catch {
                            print(error)
                        }
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
                            gbaBiosData: $gbaBiosData,
                            firmwareData: $firmwareData,
                            isRunning: $isRunning,
                            workItem: $workItem,
                            emulator: $emulator,
                            gameUrl: $gameUrl,
                            path: $path,
                            game: $game,
                            gbaGame: $gbaGame,
                            gbcGame: $gbcGame,
                            themeColor: $themeColor,
                            isPaused: $isPaused,
                            currentLibrary: $currentLibrary
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
                            themeColor: $themeColor,
                            loading: $loading,
                            currentLibrary: $currentLibrary
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
                            gbaBiosData: $gbaBiosData,
                            loggedInCloud: $loggedInCloud,
                            user: $user,
                            cloudService: $cloudService,
                            isSoundOn: $isSoundOn,
                            bios7Loaded: $bios7Loaded,
                            bios9Loaded: $bios9Loaded,
                            gbaBiosLoaded: $gbaBiosLoaded,
                            themeColor: $themeColor,
                            gameController: $gameController,
                            buttonDict: $buttonDict
                        )
                    }
                    if loading {
                        ProgressView()
                    }
                    Spacer()
                    NavigationBarView(currentView: $currentView, themeColor: $themeColor)
                }
            }
            .navigationDestination(for: String.self) { view in
                switch view {
                case "NDSGameView":
                    GameView(
                        isMenuPresented: $isMenuPresented,
                        emulator: $emulator,
                        emulatorCopy: .constant(nil),
                        bios7Data: $bios7Data,
                        bios9Data: $bios9Data,
                        firmwareData: $firmwareData,
                        gbaBiosData: .constant(nil),
                        romData: $romData,
                        gameUrl: $gameUrl,
                        user: $user,
                        cloudService: $cloudService,
                        game: $game,
                        isSoundOn: $isSoundOn,
                        themeColor: $themeColor,
                        gameName: $gameName,
                        backupFile: $backupFile,
                        gbBackupFile: .constant(nil),
                        gameController: $gameController,
                        audioManager: $audioManager,
                        isRunning: $isRunning,
                        workItem: $workItem,
                        topImage: $topImage,
                        bottomImage: $bottomImage,
                        image: .constant(nil),
                        isPaused: $isPaused,
                        buttonDict: $buttonDict
                    )
                case "GBAGameView":
                    GameView(
                        isMenuPresented: $isMenuPresented,
                        emulator: $emulator,
                        emulatorCopy: $gbaEmulatorCopy,
                        bios7Data: .constant(nil),
                        bios9Data: .constant(nil),
                        firmwareData: .constant(nil),
                        gbaBiosData: $gbaBiosData,
                        romData: $romData,
                        gameUrl: $gameUrl,
                        user: $user,
                        cloudService: $cloudService,
                        game: $gbaGame,
                        isSoundOn: $isSoundOn,
                        themeColor: $themeColor,
                        gameName: $gameName,
                        backupFile: $backupFile,
                        gbBackupFile: $gbBackupFile,
                        gameController: $gameController,
                        audioManager: $audioManager,
                        isRunning: $isRunning,
                        workItem: $workItem,
                        topImage: .constant(nil),
                        bottomImage: .constant(nil),
                        image: $gbaImage,
                        isPaused: $isPaused,
                        buttonDict: $buttonDict
                    )
                case "GBCGameView":
                    GameView(
                        isMenuPresented: $isMenuPresented,
                        emulator: $emulator,
                        emulatorCopy: .constant(nil),
                        bios7Data: .constant(nil),
                        bios9Data: .constant(nil),
                        firmwareData: .constant(nil),
                        gbaBiosData: .constant(nil),
                        romData: $romData,
                        gameUrl: $gameUrl,
                        user: $user,
                        cloudService: $cloudService,
                        game: $gbcGame,
                        isSoundOn: $isSoundOn,
                        themeColor: $themeColor,
                        gameName: $gameName,
                        backupFile: $backupFile,
                        gbBackupFile: $gbBackupFile,
                        gameController: $gameController,
                        audioManager: $audioManager,
                        isRunning: $isRunning,
                        workItem: $workItem,
                        topImage: .constant(nil),
                        bottomImage: .constant(nil),
                        image: $gbcImage,
                        isPaused: $isPaused,
                        buttonDict: $buttonDict
                    )
                default: Text("UNSUPPORTED")
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
                        .decode([ButtonMapping:String].self, from: data)

                    buttonDict = Dictionary(
                        uniqueKeysWithValues: decodedButtonMappings.map{ key, value in
                            (key, PressedButton(rawValue: Int(value) ?? 0) ?? .ButtonL)
                        }
                    )
                }
            } catch {
                buttonDict = ContentView.getDefaultMappings()
                defaults.removeObject(forKey: "buttonMappings")
                print("error while decoding button mappings: \(error)")
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
