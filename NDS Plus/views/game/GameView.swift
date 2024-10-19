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
    
    @State private var topImage: CGImage?
    @State private var bottomImage: CGImage?
    @State private var gameName = ""
    @State private var backupFile: BackupFile? = nil
    @State private var debounceTimer: Timer? = nil
    @State private var gameController: GameController?
    @State private var audioManager: AudioManager? = nil
    @State private var isRunning = false
    @State private var workItem: DispatchWorkItem? = nil
    @State private var loading = false
    @State private var isMenuPresented = false
    @State private var homePressed = false
    @State private var shouldGoHome = false
    @State private var isPaused: Bool = false
    
    @Binding var emulator: MobileEmulator?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    @Binding var game: Game?
    @Binding var shouldUpdateGame: Bool
    @Binding var isSoundOn: Bool
    @Binding var themeColor: Color
    
    @Environment(\.modelContext) private var context
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    @State private var buttonStarted: [ButtonEvent:Bool] = [ButtonEvent:Bool]()
    
    private let graphicsParser = GraphicsParser()

    private func goHome() {
        isMenuPresented = false
        
        emulator = nil
        isRunning = false
        workItem?.cancel()
        workItem = nil
        
        audioManager?.isRunning = false
        presentationMode.wrappedValue.dismiss()
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
                emu.updateInput(ButtonEvent.ButtonA, pressed)
            }
            controller.buttonA.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.ButtonB, pressed)
            }
            controller.buttonX.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.ButtonY, pressed)
            }
            controller.buttonY.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.ButtonX, pressed)
            }
            controller.leftShoulder.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.ButtonL, pressed)
            }
            controller.rightShoulder.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.ButtonR, pressed)
            }
            controller.buttonMenu.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.Start, pressed)
            }
            controller.buttonOptions?.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.Select, pressed)
            }
            controller.dpad.up.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.Up, pressed)
            }
            controller.dpad.down.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.Down, pressed)
            }
            controller.dpad.left.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.Left, pressed)
            }
            controller.dpad.right.pressedChangedHandler = { (button, value, pressed) in
                emu.updateInput(ButtonEvent.Right, pressed)
            }
            controller.buttonHome?.pressedChangedHandler = { (button, value, pressed) in
                if pressed && !homePressed {
                    homePressed = true
                    
                    isMenuPresented = !isMenuPresented
                    
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        homePressed = false
                    }
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
        emulator = MobileEmulator(
            bios7Ptr!,
            bios9Ptr!,
            firmwarePtr!,
            romPtr!
        )
        
        if let url = gameUrl {
            gameName = String(url
                .relativeString
                .split(separator: "/")
                .last
                .unsafelyUnwrapped
            )
                .removingPercentEncoding
                .unsafelyUnwrapped
            
            if let game = Game.storeGame(
                gameName: gameName,
                data: romData!,
                url: url,
                iconPtr: emulator!.getGameIconPointer()
            ) {
                context.insert(game)
                if shouldUpdateGame {
                    self.game = game
                }
            }
            
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
                        backupFile = BackupFile(entry: entries[0], gameUrl: url)
                        if let data = backupFile!.createBackupFile() {
                            emulator?.setBackup(entries[0].saveType, entries[0].ramCapacity, data)
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
        ZStack {
            if gameController?.controller?.extendedGamepad == nil {
                themeColor
            } else {
                Color.black
            }
            VStack(spacing: 0) {
                Spacer()
                DualScreenView(
                    gameController: $gameController,
                    topImage: $topImage,
                    bottomImage: $bottomImage,
                    emulator: $emulator,
                    buttonStarted: $buttonStarted,
                    audioManager: $audioManager
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
                        isMenuPresented: $isMenuPresented
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
                game: $game
            )
        }
        .onAppear {
            print(gameController?.controller?.extendedGamepad == nil)
            UIApplication.shared.isIdleTimerDisabled = true
            Task {
                await self.run()
                gameController = GameController(closure: { gameController in
                    addControllerEventListeners(gameController: gameController)
                })
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
                        audioManager?.resumeAudio()
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
    }
}
