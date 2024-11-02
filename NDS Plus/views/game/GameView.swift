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
    @State private var isMenuPresented = false
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

    private var homeButtonPressed: Bool {
        if let joypad = gameController?.controller?.extendedGamepad {
            for (key, value) in buttonEventDict {
                if value == .MainMenu {
                    switch key {
                    case .a: return joypad.buttonA.isPressed
                    case .b: return joypad.buttonB.isPressed
                    case .x: return joypad.buttonX.isPressed
                    case .y: return joypad.buttonY.isPressed
                    case .menu: return joypad.buttonMenu.isPressed
                    case .options: return joypad.buttonOptions?.isPressed ?? false
                    case .home: return joypad.buttonHome?.isPressed ?? false
                    case .left: return joypad.dpad.left.isPressed
                    case .right: return joypad.dpad.right.isPressed
                    case .down: return joypad.dpad.down.isPressed
                    case .up: return joypad.dpad.up.isPressed
                    case .leftShoulder: return joypad.leftShoulder.isPressed
                    case .rightShoulder: return joypad.rightShoulder.isPressed
                    case .leftTrigger: return joypad.leftTrigger.isPressed
                    case .rightTrigger: return joypad.rightTrigger.isPressed
                    case .leftThumbstick: return joypad.leftThumbstickButton?.isPressed ?? false
                    case .rightThumbstick: return joypad.rightThumbstickButton?.isPressed ?? false
                    case .noButton: return false
                    }
                }
            }
        }

        return false
    }


    private func checkIfHotKey(_ mapping: ButtonMapping, _ pressed: Bool) -> Bool {
        if let value = buttonEventDict[mapping] {
            switch value {
            case .MainMenu:
                let startInterval = Date.now.timeIntervalSince1970
                var nextInterval = Date.now.timeIntervalSince1970

                DispatchQueue.global().async {
                    while (homeButtonPressed) {
                        nextInterval = Date.now.timeIntervalSince1970

                        if (nextInterval - startInterval > 0.5) && !homePressed {
                            homePressed = true
                            isMenuPresented = !isMenuPresented

                            emulator?.setPause(isMenuPresented)

                            DispatchQueue.main.async {
                                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                    homePressed = false

                                }
                            }
                        }
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
            default: return false
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
                            data: data
                        )
                    }
                }
            } else {
                backupFile?.saveGame(ptr: ptr, backupLength: backupLength)
            }
        }
        
    }
    
    private func addControllerEventListeners(gameController: GCController?) {
        if let emu = emulator, let controller = gameController?.extendedGamepad {
            controller.buttonB.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.b, pressed) {
                    emu.updateInput(buttonEventDict[.b] ?? .ButtonA, pressed)
                }
            }
            controller.buttonA.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.a, pressed) {
                    emu.updateInput(buttonEventDict[.a] ?? .ButtonB, pressed)
                }
            }
            controller.buttonX.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.x, pressed) {
                    emu.updateInput(buttonEventDict[.x] ?? .ButtonY, pressed)
                }
            }
            controller.buttonY.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.y, pressed) {
                    emu.updateInput(buttonEventDict[.y] ?? .ButtonX, pressed)
                }
            }
            controller.leftShoulder.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.leftShoulder, pressed) {
                    emu.updateInput(buttonEventDict[.leftShoulder] ?? ButtonEvent.ButtonL, pressed)
                }
            }
            controller.rightShoulder.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightShoulder, pressed) {
                    emu.updateInput(buttonEventDict[.rightShoulder] ?? ButtonEvent.ButtonR, pressed)
                }
            }
            controller.buttonMenu.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.menu, pressed) {
                    emu.updateInput(buttonEventDict[.menu] ?? ButtonEvent.Start, pressed)
                }
            }
            controller.buttonOptions?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.options, pressed) {
                    emu.updateInput(buttonEventDict[.options] ?? ButtonEvent.Select, pressed)
                }
            }
            controller.dpad.up.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.up, pressed) {
                    emu.updateInput(buttonEventDict[.up] ?? ButtonEvent.Up, pressed)
                }
            }
            controller.dpad.down.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.down, pressed) {
                    emu.updateInput(buttonEventDict[.down] ?? ButtonEvent.Down, pressed)
                }
            }
            controller.dpad.left.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.left, pressed) {
                    emu.updateInput(buttonEventDict[.left] ?? ButtonEvent.Left, pressed)
                }
            }
            controller.dpad.right.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.right, pressed) {
                    emu.updateInput(buttonEventDict[.right] ?? ButtonEvent.Right, pressed)
                }
            }
            controller.buttonHome?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.home, pressed) {
                    emu.updateInput(buttonEventDict[.home] ?? ButtonEvent.ButtonHome, pressed)
                }
            }
            controller.leftThumbstickButton?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.leftThumbstick, pressed) {
                    emu.updateInput(buttonEventDict[.leftThumbstick] ?? ButtonEvent.QuickSave, pressed)
                }
            }

            controller.rightThumbstickButton?.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightThumbstick, pressed) {
                    emu.updateInput(buttonEventDict[.rightThumbstick] ?? ButtonEvent.QuickLoad, pressed)
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
                    emu.updateInput(buttonEventDict[.leftTrigger] ?? ButtonEvent.ControlStick, pressed)
                }
            }

            controller.rightTrigger.pressedChangedHandler = { (button, value, pressed) in
                if !checkIfHotKey(.rightTrigger, pressed) {
                    emu.updateInput(buttonEventDict[.rightTrigger] ?? ButtonEvent.ControlStick, pressed)
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
                            if let saveData = await self.cloudService!.getSave(saveName: BackupFile.getSaveName(gameUrl: url)) {
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
                            
                            let audioSamples = Array(UnsafeBufferPointer(start: audioBufferPtr, count: Int(audioBufferLength)))
                            
                            self.audioManager?.updateBuffer(samples: audioSamples)
                            
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
                    isHoldButtonsPresented: $isHoldButtonsPresented
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
