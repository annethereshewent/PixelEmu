//
//  GameView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/18/24.
//

import SwiftUI
import DSEmulatorMobile
import GBAEmulatorMobile
import GBCEmulatorMobile
import GoogleSignIn
import GameController

struct GameView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var context

    @EnvironmentObject var orientationInfo: OrientationInfo

    @State private var debounceTimer: Timer? = nil

    @State private var loading = false

    @State private var homePressed = false
    @State private var controlStickKeyPressed = false
    @State private var shouldGoHome = false

    @State private var buttonStarted: [PressedButton:Bool] = [PressedButton:Bool]()

    @State private var isHoldButtonsPresented = false
    @State private var heldButtons: Set<PressedButton> = []

    @State private var stateManager: StateManager?

    @State private var useControlStick = false
    @State private var quickSaveLoadKeyPressed = false

    @State private var controller: GCController? = GCController.controllers().first

    @Binding var isMenuPresented: Bool
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var emulatorCopy: (any EmulatorWrapper)?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var gbaBiosData: Data?
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    @Binding var game: (any Playable)?
    @Binding var isSoundOn: Bool
    @Binding var themeColor: Color

    @Binding var gameName: String
    @Binding var backupFile: BackupFile?
    @Binding var gbaBackupFile: GBABackupFile?
    @Binding var gameController: GameController?

    @Binding var audioManager: AudioManager?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var topImage: CGImage?
    @Binding var bottomImage: CGImage?

    @Binding var image: CGImage?

    @Binding var isPaused: Bool
    @Binding var buttonDict: [ButtonMapping:PressedButton]

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)


    private let graphicsParser = GraphicsParser()

    private var screenPadding: CGFloat {
        if orientationInfo.orientation == .portrait {
            if controller?.extendedGamepad == nil {
                return 120
            }
        }


        return 0
    }

    private func goHome() {
        emulator?.setPaused(true)

        audioManager?.muteAudio()

        presentationMode.wrappedValue.dismiss()
    }

    private func checkIfHotKey(_ mapping: ButtonMapping, _ pressed: Bool) -> Bool {
        if let value = buttonDict[mapping] {
            switch value {
            case .MainMenu:
                if pressed && !homePressed {
                    homePressed = true
                    isMenuPresented = !isMenuPresented

                    if isMenuPresented {
                        audioManager?.muteAudio()
                    }

                    emulator?.setPaused(isMenuPresented)

                    Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                        homePressed = false

                    }
                }
                return true
            case .ControlStick:
                if pressed && !controlStickKeyPressed {
                    controlStickKeyPressed = true

                    useControlStick = !useControlStick

                    if let emu = emulator {
                        if useControlStick {
                            try! emu.pressScreen()
                            try! emu.touchScreenController(0, 0)
                        } else {
                            try! emu.releaseScreen()
                        }
                    }

                    Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                        controlStickKeyPressed = false
                    }
                }
                return true
            case .QuickLoad:
                if pressed && !quickSaveLoadKeyPressed {
                    quickSaveLoadKeyPressed = true

                    do {
                        try stateManager?.loadSaveState(currentState: nil, isQuickSave: true)
                    } catch {
                        print(error)
                    }

                    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                        quickSaveLoadKeyPressed = false
                    }
                }

                return true
            case .QuickSave:
                if pressed && !quickSaveLoadKeyPressed {
                    quickSaveLoadKeyPressed = true

                    if let emu = emulator {
                        let dataPtr = try! emu.createSaveState()
                        let dataSize = try! emu.compressedLength()

                        let bufferPtr = UnsafeBufferPointer(start: dataPtr, count: Int(dataSize))
                        let data = Data(bufferPtr)

                        do {
                            try stateManager?.createSaveState(data: data, saveName: "quick_save.save", timestamp: Int(Date().timeIntervalSince1970))
                        } catch {
                            print(error)
                        }

                        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                            quickSaveLoadKeyPressed = false
                        }
                    }
                }
                return true
            default: break
            }
        }

        return false
    }

    private func checkSaves() {
        if let emu = emulator {
            if emu.hasSaved() {
                if game!.type != .gbc {
                    try! emu.setSaved(false)
                }
                debounceTimer?.invalidate()

                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { _ in
                    self.saveGame()
                }
            }
        }
    }

    private func saveGame() {
        if let game = game {
            switch game.type {
            case .nds: saveDsGame()
            case .gba: saveGbaGame()
            case .gbc: print("warning, save game not implemented")
            }
        }
    }

    private func saveGbaGame() {
        if let emu = emulator {
            let ptr = emu.backupPointer()
            let backupLength = Int(emu.backupLength())

            if let cloudService = cloudService {
                if let url = gameUrl {
                    let buffer = UnsafeBufferPointer(start: ptr, count: backupLength)

                    let data = Data(buffer)

                    Task {
                        await cloudService.uploadSave(
                            saveName: BackupFile.getSaveName(gameUrl: url),
                            data: data,
                            saveType: .gba
                        )
                    }
                }
            } else {
                backupFile?.saveGame(ptr: ptr, backupLength: backupLength)
            }
        }
    }

    private func saveDsGame() {
        if let emu = emulator {
            let ptr = emu.backupPointer();

            let backupLength = Int(emu.backupLength())

            if let cloudService = cloudService {
                if let url = gameUrl {
                    let buffer = UnsafeBufferPointer(start: ptr, count: backupLength)

                    let data = Data(buffer)

                    Task {
                        await cloudService.uploadSave(
                            saveName: BackupFile.getSaveName(gameUrl: url),
                            data: data,
                            saveType: .nds
                        )
                    }
                }
            } else {
                backupFile?.saveGame(ptr: ptr, backupLength: backupLength)
            }
        }
    }

    private func updateInput(_ mapping: ButtonMapping, _ defaultButton: PressedButton, _ pressed: Bool) {
        if let emu = emulator {
            if let value = buttonDict[mapping] {
                if value != .MainMenu {
                    emu.updateInput(value, pressed)
                }
            } else {
                emu.updateInput(defaultButton, pressed)
            }
        }
    }

    private func addControllerEventListeners(_ controller: GCController) {
        if let controller = controller.extendedGamepad {
            controller.buttonB.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.b, pressed) {
                    updateInput(.b, .ButtonCross, pressed)
                }
            }
            controller.buttonA.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.a, pressed) {
                    updateInput(.a, .ButtonCircle, pressed)
                }
            }
            controller.buttonX.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.x, pressed) {
                    updateInput(.x, .ButtonTriangle, pressed)
                }
            }
            controller.buttonY.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.y, pressed) {
                    updateInput(.y, .ButtonSquare, pressed)
                }
            }
            controller.leftShoulder.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.leftShoulder, pressed) {
                    updateInput(.leftShoulder, .ButtonL, pressed)
                }
            }
            controller.rightShoulder.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightShoulder, pressed) {
                    updateInput(.rightShoulder, .ButtonR, pressed)
                }
            }
            controller.buttonMenu.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.menu, pressed) {
                    updateInput(.menu, .Start, pressed)
                }
            }
            controller.buttonOptions?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.options, pressed) {
                    updateInput(.options, .Select, pressed)
                }
            }
            controller.dpad.up.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.up, pressed) {
                    updateInput(.up, .Up, pressed)
                }
            }
            controller.dpad.down.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.down, pressed) {
                    updateInput(.down, .Down, pressed)
                }
            }
            controller.dpad.left.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.left, pressed) {
                    updateInput(.left, .Left, pressed)
                }
            }
            controller.dpad.right.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.right, pressed) {
                    updateInput(.right, .Right, pressed)
                }
            }
            controller.buttonHome?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.home, pressed) {
                    updateInput(.home, .MainMenu, pressed)
                }
            }
            controller.leftThumbstickButton?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.leftThumbstick, pressed) {
                    updateInput(.leftThumbstick, .QuickSave, pressed)
                }
            }

            controller.rightThumbstickButton?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightThumbstick, pressed) {
                    updateInput(.rightThumbstick, .QuickLoad, pressed)
                }
            }

            controller.leftThumbstick.valueChangedHandler = { (controller, x, y) in
                if useControlStick {
                    if let emu = emulator {
                        try! emu.touchScreenController(x, -y)
                    }
                }
            }

            controller.leftTrigger.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.leftTrigger, pressed) {
                    updateInput(.leftTrigger, .ControlStick, pressed)
                }
            }

            controller.rightTrigger.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightTrigger, pressed) {
                    updateInput(.rightTrigger, .ControlStick, pressed)
                }
            }
        }
    }
    private func loadNdsSave(_ game: Game) async {
        let gameCode = try! emulator?.getGameCode()

        if let entries = GameEntry.decodeGameDb() {
            let entries = entries.filter { $0.gameCode == gameCode }
            if entries.count > 0 {
                if user != nil {
                    if let url = gameUrl {
                        loading = true
                        if let saveData = await self.cloudService!.getSave(saveName: BackupFile.getSaveName(gameUrl: url), saveType: .nds) {
                            let ptr = BackupFile.getPointer(saveData)
                            try! emulator?.setBackup(entries[0].saveType, entries[0].ramCapacity, ptr)
                        } else {
                            let ptr = BackupFile.getPointer(Data())
                            try! emulator?.setBackup(entries[0].saveType, entries[0].ramCapacity, ptr)
                        }
                        loading = false
                    }
                } else {
                    var isStale = false
                    do {
                        let url = try URL(resolvingBookmarkData: game.bookmark, bookmarkDataIsStale: &isStale)
                        backupFile = BackupFile(entry: entries[0], gameUrl: url)
                        if let data = backupFile!.createBackupFile() {
                            try! emulator?.setBackup(entries[0].saveType, entries[0].ramCapacity, data)
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }

    private func loadGbaSave() async {
        if let emu = emulator, let gameUrl = gameUrl {
            loading = true
            if let saveData = await self.cloudService?.getSave(saveName: BackupFile.getSaveName(gameUrl: gameUrl), saveType: .gba) {
                let ptr = BackupFile.getPointer(saveData)
                try! emu.loadSave(ptr)
            } else {
                gbaBackupFile = GBABackupFile(gameUrl: gameUrl, backupSize: Int(emu.backupLength()))
                if let ptr = gbaBackupFile!.createBackupFile() {
                    try! emu.loadSave(ptr)
                }
            }
            loading = false
        }
    }

    private func run() async {
        let romArr: [UInt8] = Array(romData!)
        var romPtr: UnsafeBufferPointer<UInt8>? = nil
        romArr.withUnsafeBufferPointer() { ptr in
            romPtr = ptr
        }

        if emulator == nil {
            switch game!.type {
            case .nds:
                let bios7Arr: [UInt8] = Array(bios7Data!)
                let bios9Arr: [UInt8] = Array(bios9Data!)
                let firmwareArr: [UInt8] = if let firmware = firmwareData {
                    Array(firmware)
                } else {
                    []
                }

                var bios7Ptr: UnsafeBufferPointer<UInt8>? = nil
                var bios9Ptr: UnsafeBufferPointer<UInt8>? = nil
                var firmwarePtr: UnsafeBufferPointer<UInt8>? = nil


                bios7Arr.withUnsafeBufferPointer() { ptr in
                    bios7Ptr = ptr
                }

                bios9Arr.withUnsafeBufferPointer() { ptr in
                    bios9Ptr = ptr
                }

                firmwareArr.withUnsafeBufferPointer() { ptr in
                    firmwarePtr = ptr
                }


                emulator =  DSEmulatorWrapper(emu: MobileEmulator(
                    bios7Ptr!,
                    bios9Ptr!,
                    firmwarePtr!,
                    romPtr!
                ))
            case .gba:
                let biosArr = Array(gbaBiosData!)
                var biosPtr: UnsafeBufferPointer<UInt8>!

                biosArr.withUnsafeBufferPointer { ptr in
                    biosPtr = ptr
                }
                emulator = GBAEmulatorWrapper(emu: GBAEmulator())
                if let romPtr = romPtr {
                    try! emulator!.load(romPtr)
                }
                try! emulator!.loadBios(biosPtr)
            case .gbc:
                if let romPtr = romPtr {
                    emulator = GBCEmulatorWrapper(emu: GBCMobileEmulator())

                    try! emulator!.load(romPtr)
                }
            }
        }

        if let game = game {
            switch game.type {
            case .nds: await loadNdsSave(game as! Game)
            case .gba: await loadGbaSave()
            case .gbc: print("Warning, load save not implemented")
            }
            isRunning = true

            audioManager = AudioManager()

            if game.type == .nds {
                audioManager!.startMicrophoneAndAudio()
            } else {
                audioManager!.startAudio()
            }

            if !isSoundOn {
                audioManager?.muteAudio()
            }

            workItem = DispatchWorkItem {
                mainGameLoop()
            }

            DispatchQueue.global().async(execute: workItem!)
        }
    }

    private func mainGameLoop() {
        if let emu = emulator, let game = game {
            while true {
                DispatchQueue.main.sync {
                    emu.stepFrame()

                    if game.type == .nds {
                        if let player = audioManager {
                            if let bufferPtr = player.getBufferPtr() {
                                try! emu.updateAudioBuffer(bufferPtr)
                            }
                        }
                    }


                    switch game.type {
                    case .nds:
                        let aPixels = try! emu.getEngineAPicturePointer()

                        var imageA: CGImage? = nil
                        var imageB: CGImage? = nil

                        if let image = graphicsParser.fromPointer(ptr: aPixels) {
                            imageA = image
                        }

                        let bPixels = try! emu.getEngineBPicturePointer()

                        if let image = graphicsParser.fromPointer(ptr: bPixels) {
                            imageB = image
                        }

                        if emu.isTopA() {
                            topImage = imageA
                            bottomImage = imageB
                        } else {
                            topImage = imageB
                            bottomImage = imageA
                        }
                    case .gba:
                        let pixels = try! emu.getPicturePtr()

                        if let image = graphicsParser.fromGBAPointer(ptr: pixels) {
                            self.image = image
                        }
                    case .gbc:
                        let pixels = try! emu.getPicturePtr()

                        if let image = graphicsParser.fromGBCPointer(ptr: pixels) {
                            self.image = image
                        }
                    }

                    let playerPaused = audioManager?.playerPaused ?? true

                    if !playerPaused && game.type != .gbc {
                        let audioBufferLength = emu.audioBufferLength()

                        let audioBufferPtr = emu.audioBufferPtr()
                        
                        let audioSamples = Array(UnsafeBufferPointer(start: audioBufferPtr, count: Int(audioBufferLength)))
                        self.audioManager?.updateBuffer(samples: audioSamples)
                    }

                    self.checkSaves()
                }

                if !isRunning {
                    break
                }
            }
        }
    }

    private func resumeGame() {
        if let emu = emulatorCopy {
            isPaused = false

            // this is a hack, otherwise things won't work right when resuming game from home screen.
            // TODO: figure out why
            // Update: still haven't figured out why it's busted
            emulator = emu
            emulatorCopy = nil

            if isSoundOn {
                audioManager?.resumeAudio()
            }
            workItem = DispatchWorkItem {
                mainGameLoop()
            }

            DispatchQueue.global().async(execute: workItem!)
        }
    }

    var body: some View {
        ZStack {
            if gameController?.controller?.extendedGamepad == nil {
                themeColor
            } else {
                Color.black
            }
            if !loading {
                VStack(spacing: 0) {
                    if orientationInfo.orientation == .portrait {
                        Spacer()
                    }
                    switch game?.type ?? .nds {
                    case .nds:
                        DualScreenViewWrapper(
                            gameController: $gameController,
                            topImage: $topImage,
                            bottomImage: $bottomImage,
                            emulator: $emulator,
                            buttonStarted: $buttonStarted,
                            audioManager: $audioManager,
                            isSoundOn: $isSoundOn,
                            isHoldButtonsPresented: $isHoldButtonsPresented,
                            heldButtons: $heldButtons,
                            themeColor: $themeColor
                        )
                        if gameController?.controller?.extendedGamepad == nil {
                            TouchControlsView(
                                emulator: $emulator,
                                audioManager: $audioManager,
                                workItem: $workItem,
                                isRunning: $isRunning,
                                buttonStarted: $buttonStarted,
                                bios7Data: $bios7Data,
                                bios9Data: $bios9Data,
                                firmwareData: $firmwareData,
                                romData: $romData,
                                gameName: $gameName,
                                isMenuPresented: $isMenuPresented,
                                isHoldButtonsPresented: $isHoldButtonsPresented,
                                heldButtons: $heldButtons
                            )
                        }
                    case .gba:
                        VStack {
                            GBScreenViewWrapper(
                                gameType: .gba,
                                gameController: $gameController,
                                image: $image,
                                emulator: $emulator,
                                buttonStarted: $buttonStarted,
                                audioManager: $audioManager,
                                isSoundOn: $isSoundOn,
                                isHoldButtonsPresented: $isHoldButtonsPresented,
                                heldButtons: $heldButtons,
                                themeColor: $themeColor
                            )
                            .padding(.top, screenPadding)
                            if gameController?.controller?.extendedGamepad == nil {
                                GBTouchControlsView(
                                    gameType: .gba,
                                    emulator: $emulator,
                                    emulatorCopy: $emulatorCopy,
                                    audioManager: $audioManager,
                                    workItem: $workItem,
                                    isRunning: $isRunning,
                                    buttonStarted: $buttonStarted,
                                    gameName: $gameName,
                                    isMenuPresented: $isMenuPresented,
                                    isHoldButtonsPresented: $isHoldButtonsPresented,
                                    heldButtons: $heldButtons,
                                    isPaused: $isPaused,
                                    shouldGoHome: $shouldGoHome
                                )
                            }
                        }
                    case .gbc:
                        GBScreenViewWrapper(
                            gameType: .gbc,
                            gameController: $gameController,
                            image: $image,
                            emulator: $emulator,
                            buttonStarted: $buttonStarted,
                            audioManager: $audioManager,
                            isSoundOn: $isSoundOn,
                            isHoldButtonsPresented: $isHoldButtonsPresented,
                            heldButtons: $heldButtons,
                            themeColor: $themeColor
                        )
                        .padding(.top, screenPadding)
                        if gameController?.controller?.extendedGamepad == nil {
                            GBTouchControlsView(
                                gameType: .gbc,
                                emulator: $emulator,
                                emulatorCopy: $emulatorCopy,
                                audioManager: $audioManager,
                                workItem: $workItem,
                                isRunning: $isRunning,
                                buttonStarted: $buttonStarted,
                                gameName: $gameName,
                                isMenuPresented: $isMenuPresented,
                                isHoldButtonsPresented: $isHoldButtonsPresented,
                                heldButtons: $heldButtons,
                                isPaused: $isPaused,
                                shouldGoHome: $shouldGoHome
                            )
                        }
                    }
                }
            } else {
                VStack {
                    Image("Launch Screen Logo")
                        .resizable()
                        .frame(maxWidth: 342, maxHeight: 272)
                    ProgressView()
                }
            }
        }
        .sheet(
            isPresented: $isMenuPresented
        ) {
            if let game = game {
                switch game.type {
                case .nds:
                    GameMenuView(
                        gameType: .nds,
                        emulator: $emulator,
                        isRunning: $isRunning,
                        workItem: $workItem,
                        audioManager: $audioManager,
                        isMenuPresented: $isMenuPresented,
                        gameName: $gameName,
                        biosData: .constant(nil),
                        bios7Data: $bios7Data,
                        bios9Data: $bios9Data,
                        firmwareData: $firmwareData,
                        romData: $romData,
                        shouldGoHome: $shouldGoHome,
                        game: $game,
                        isHoldButtonsPresented: $isHoldButtonsPresented,
                        isSoundOn: $isSoundOn,
                        gameController: $gameController
                    )
                case .gba:
                    GameMenuView(
                        gameType: .gba,
                        emulator: $emulator,
                        isRunning: $isRunning,
                        workItem: $workItem,
                        audioManager: $audioManager,
                        isMenuPresented: $isMenuPresented,
                        gameName: $gameName,
                        biosData: $gbaBiosData,
                        bios7Data: .constant(nil),
                        bios9Data: .constant(nil),
                        firmwareData: .constant(nil),
                        romData: $romData,
                        shouldGoHome: $shouldGoHome,
                        game: $game,
                        isHoldButtonsPresented: $isHoldButtonsPresented,
                        isSoundOn: $isSoundOn,
                        gameController: $gameController
                    )
                case .gbc: Text("TODO: Not implemented")
                }
            }

        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            Task {
                if !isRunning {
                    emulatorCopy = nil
                    if let game = game {
                        gameController = GameController() { controller in
                            addControllerEventListeners(controller)
                        }

                    }
                    await self.run()
                } else {
                    if isSoundOn {
                        audioManager?.resumeAudio()
                    }
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            audioManager?.stopMicrophone()
        }
        .onChange(of: shouldGoHome) {
            if shouldGoHome {
                goHome()
            }
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                if isPaused {
                    if let emu = emulator {
                        isPaused = false

                        emu.setPaused(false)
                        if isSoundOn {
                            audioManager?.resumeAudio()
                        }
                    }
                }
                break
            case .inactive:
                break
            case .background:
                if let emu = emulator {
                    isPaused = true
                    emu.setPaused(true)
                    audioManager?.muteAudio()
                }
                break
            default:
                break
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .ignoresSafeArea(.all)
        .edgesIgnoringSafeArea(.all)
        .statusBarHidden()
    }

}
