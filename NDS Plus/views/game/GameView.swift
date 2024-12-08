//
//  GameView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/18/24.
//

import SwiftUI
import DSEmulatorMobile
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
    @State private var isPaused: Bool = false

    @State private var buttonStarted: [ButtonEvent:Bool] = [ButtonEvent:Bool]()

    @State private var isHoldButtonsPresented = false
    @State private var heldButtons: Set<ButtonEvent> = []

    @State private var stateManager: StateManager?

    @State private var useControlStick = false
    @State private var quickSaveLoadKeyPressed = false

    @Binding var isMenuPresented: Bool
    @Binding var emulator: MobileEmulator?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    @Binding var game: Game?
    @Binding var isSoundOn: Bool
    @Binding var themeColor: Color
    
    @Binding var gameName: String
    @Binding var backupFile: BackupFile?
    @Binding var gameController: GameController?
    
    @Binding var audioManager: AudioManager?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var topImage: CGImage?
    @Binding var bottomImage: CGImage?

    @Binding var buttonEventDict: [ButtonMapping:ButtonEvent]

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    
    private let graphicsParser = GraphicsParser()

    private func goHome() {
        emulator?.setPause(true)
        audioManager?.muteAudio()

        presentationMode.wrappedValue.dismiss()
    }

    private func checkIfHotKey(_ mapping: ButtonMapping, _ pressed: Bool) -> Bool {
        if let value = buttonEventDict[mapping] {
            switch value {
            case .MainMenu:
                if pressed && !homePressed {
                    homePressed = true
                    isMenuPresented = !isMenuPresented

                    if isMenuPresented {
                        audioManager?.muteAudio()
                    }

                    emulator?.setPause(isMenuPresented)

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
                            emu.pressScreen()
                            emu.touchScreenController(0, 0)
                        } else {
                            emu.releaseScreen()
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
                        let dataPtr = emu.createSaveState()
                        let dataSize = emu.compressedLength()

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
                emu.setSaved(false)
                debounceTimer?.invalidate()
                
                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { _ in
                    self.saveGame()
                }
            }
        }
    }
    
    private func saveGame() {
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

    private func updateEmuInput(_ mapping: ButtonMapping, _ defaultButton: ButtonEvent, _ pressed: Bool) {
        if let emu = emulator {
            if let value = buttonEventDict[mapping] {
                if value != .MainMenu {
                    emu.updateInput(value, pressed)
                }
            } else {
                emu.updateInput(defaultButton, pressed)
            }
        }
    }

    private func addControllerEventListeners(gameController: GCController?) {
        if let controller = gameController?.extendedGamepad {
            controller.buttonB.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.b, pressed) {
                    updateEmuInput(.b, .ButtonA, pressed)
                }
            }
            controller.buttonA.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.a, pressed) {
                    updateEmuInput(.a, .ButtonB, pressed)
                }
            }
            controller.buttonX.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.x, pressed) {
                    updateEmuInput(.x, .ButtonY, pressed)
                }
            }
            controller.buttonY.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.y, pressed) {
                    updateEmuInput(.y, .ButtonX, pressed)
                }
            }
            controller.leftShoulder.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.leftShoulder, pressed) {
                    updateEmuInput(.leftShoulder, .ButtonL, pressed)
                }
            }
            controller.rightShoulder.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightShoulder, pressed) {
                    updateEmuInput(.rightShoulder, .ButtonR, pressed)
                }
            }
            controller.buttonMenu.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.menu, pressed) {
                    updateEmuInput(.menu, .Start, pressed)
                }
            }
            controller.buttonOptions?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.options, pressed) {
                    updateEmuInput(.options, .Select, pressed)
                }
            }
            controller.dpad.up.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.up, pressed) {
                    updateEmuInput(.up, .Up, pressed)
                }
            }
            controller.dpad.down.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.down, pressed) {
                    updateEmuInput(.down, .Down, pressed)
                }
            }
            controller.dpad.left.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.left, pressed) {
                    updateEmuInput(.left, .Left, pressed)
                }
            }
            controller.dpad.right.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.right, pressed) {
                    updateEmuInput(.right, .Right, pressed)
                }
            }
            controller.buttonHome?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.home, pressed) {
                    updateEmuInput(.home, .MainMenu, pressed)
                }
            }
            controller.leftThumbstickButton?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.leftThumbstick, pressed) {
                    updateEmuInput(.leftThumbstick, .QuickSave, pressed)
                }
            }

            controller.rightThumbstickButton?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightThumbstick, pressed) {
                    updateEmuInput(.rightThumbstick, .QuickLoad, pressed)
                }
            }

            controller.leftThumbstick.valueChangedHandler = { (controller, x, y) in
                if useControlStick {
                    if let emu = emulator {
                        emu.touchScreenController(x, -y)
                    }
                }
            }

            controller.leftTrigger.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.leftTrigger, pressed) {
                    updateEmuInput(.leftTrigger, .ControlStick, pressed)
                }
            }

            controller.rightTrigger.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightTrigger, pressed) {
                    updateEmuInput(.rightTrigger, .ControlStick, pressed)
                }
            }
        }
    }
    private func run() async {
        let bios7Arr: [UInt8] = Array(bios7Data!)
        let bios9Arr: [UInt8] = Array(bios9Data!)
        let firmwareArr: [UInt8] = if let firmware = firmwareData {
            Array(firmware)
        } else {
            []
        }
        let romArr: [UInt8] = Array(romData!)
        
        var bios7Ptr: UnsafeBufferPointer<UInt8>? = nil
        var bios9Ptr: UnsafeBufferPointer<UInt8>? = nil
        var firmwarePtr: UnsafeBufferPointer<UInt8>? = nil
        var romPtr: UnsafeBufferPointer<UInt8>? = nil
        
        bios7Arr.withUnsafeBufferPointer() { ptr in
            bios7Ptr = ptr
        }
        
        bios9Arr.withUnsafeBufferPointer() { ptr in
            bios9Ptr = ptr
        }
        
        firmwareArr.withUnsafeBufferPointer() { ptr in
            firmwarePtr = ptr
        }
        romArr.withUnsafeBufferPointer() { ptr in
            romPtr = ptr
        }
        if emulator == nil {
            emulator = MobileEmulator(
                bios7Ptr!,
                bios9Ptr!,
                firmwarePtr!,
                romPtr!
            )
        }
        
        if let game = game {
            let gameCode = emulator?.getGameCode()
            
            if let entries = GameEntry.decodeGameDb() {
                let entries = entries.filter { $0.gameCode == gameCode }
                if entries.count > 0 {
                    if user != nil {
                        if let url = gameUrl {
                            loading = true
                            if let saveData = await self.cloudService!.getSave(saveName: BackupFile.getSaveName(gameUrl: url), saveType: .nds) {
                                let ptr = BackupFile.getPointer(saveData)
                                emulator?.setBackup(entries[0].saveType, entries[0].ramCapacity, ptr)
                            } else {
                                let ptr = BackupFile.getPointer(Data())
                                emulator?.setBackup(entries[0].saveType, entries[0].ramCapacity, ptr)
                            }
                            loading = false
                        }
                    } else {
                        var isStale = false
                        do {
                            let url = try URL(resolvingBookmarkData: game.bookmark, bookmarkDataIsStale: &isStale)
                            backupFile = BackupFile(entry: entries[0], gameUrl: url)
                            if let data = backupFile!.createBackupFile() {
                                emulator?.setBackup(entries[0].saveType, entries[0].ramCapacity, data)
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            isRunning = true
            
            audioManager = AudioManager()

            audioManager!.startMicrophoneAndAudio()

            if !isSoundOn {
                audioManager?.muteAudio()
            }
            
            workItem = DispatchWorkItem {
                if let emu = emulator {
                    while true {
                        DispatchQueue.main.sync {
                            emu.stepFrame()
                            
                            if let player = audioManager {
                                if let bufferPtr = player.getBufferPtr() {
                                    emu.updateAudioBuffer(bufferPtr)
                                }
                            }
                            
                            let aPixels = emu.getEngineAPicturePointer()
                            
                            var imageA: CGImage? = nil
                            var imageB: CGImage? = nil
                            
                            if let image = graphicsParser.fromPointer(ptr: aPixels) {
                                imageA = image
                            }
                            
                            let bPixels = emu.getEngineBPicturePointer()
                            
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
                            
                            let audioBufferLength = emu.audioBufferLength()
                        
                            let audioBufferPtr = emu.audioBufferPtr()

                            let playerPaused = audioManager?.playerPaused ?? true

                            if !playerPaused {
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
            
            DispatchQueue.global().async(execute: workItem!)
        }
    }
    
    var body: some View {
        if !loading {
            ZStack {
                if gameController?.controller?.extendedGamepad == nil {
                    themeColor
                } else {
                    Color.black
                }
                VStack(spacing: 0) {
                    if orientationInfo.orientation == .portrait {
                        Spacer()
                    }
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
                }
            }
            .sheet(
                isPresented: $isMenuPresented
            ) {
                GameMenuView(
                    emulator: $emulator,
                    isRunning: $isRunning,
                    workItem: $workItem,
                    audioManager: $audioManager,
                    isMenuPresented: $isMenuPresented,
                    gameName: $gameName,
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
            }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true

                if let emu = emulator, let bios7Data = bios7Data, let bios9Data = bios9Data, let romData = romData, let game = game {
                    stateManager = StateManager(
                        emu: emu,
                        game: game,
                        context: context,
                        bios7Data: bios7Data,
                        bios9Data: bios9Data,
                        romData: romData,
                        firmwareData: firmwareData
                    )
                }

                Task {
                    if !isRunning {
                        await self.run()
                        gameController = GameController(closure: { gameController in
                            addControllerEventListeners(gameController: gameController)
                        })
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
                            emu.setPause(false)
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
                        emu.setPause(true)
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
        } else {
            ZStack {
                themeColor
                VStack {
                    Image("Launch Screen Logo")
                        .resizable()
                        .frame(maxWidth: 342, maxHeight: 272)
                    ProgressView()
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
            .edgesIgnoringSafeArea(.all)
            .statusBarHidden()
        }
    }
}
