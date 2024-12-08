//
//  GBAGameView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/29/24.
//

import SwiftUI
import GBAEmulatorMobile
import GoogleSignIn
import GameController

struct GBAGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var context

    @EnvironmentObject var orientationInfo: OrientationInfo

    @State private var debounceTimer: Timer? = nil

    @State private var loading = false

    @State private var homePressed = false
    @State private var controlStickKeyPressed = false
    @State private var shouldGoHome = false

    @State private var buttonStarted: [GBAButtonEvent:Bool] = [GBAButtonEvent:Bool]()

    @State private var isHoldButtonsPresented = false
    @State private var heldButtons: Set<GBAButtonEvent> = []

    @State private var stateManager: StateManager?

    @State private var quickSaveLoadKeyPressed = false

    @Binding var isMenuPresented: Bool
    @Binding var emulator: GBAEmulator?
    @Binding var emulatorCopy: GBAEmulator?
    @Binding var biosData: Data?
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    @Binding var game: GBAGame?
    @Binding var isSoundOn: Bool
    @Binding var themeColor: Color
    
    @Binding var gameName: String
    @Binding var backupFile: GBABackupFile?
    @Binding var gameController: GameController?
    @Binding var audioManager: AudioManager?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var image: CGImage?

    @Binding var isPaused: Bool
    @Binding var buttonEventDict: [ButtonMapping:GBAButtonEvent]

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private let graphicsParser = GraphicsParser()

    private var screenPadding: CGFloat {
        if orientationInfo.orientation == .portrait {
            if gameController?.controller?.extendedGamepad == nil {
                return 120
            }
        }


        return 0
    }

    private func goHome() {
        // this isn't working, pause within swift instead of rust for now
        // emulator?.setPaused(true)
        audioManager?.muteAudio()

        isPaused = true
        workItem?.cancel()
        workItem = nil

        // presentationMode.wrappedValue.dismiss()
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
            let ptr = emu.backupFilePointer();
            let backupLength = Int(emu.backupFileSize())
            // TODO: implement cloud saves for GBA
//            if let cloudService = cloudService {
//                if let url = gameUrl {
//                    let buffer = UnsafeBufferPointer(start: ptr, count: backupLength)
//
//                    let data = Data(buffer)
//
//                    Task {
//                        await cloudService.uploadSave(
//                            saveName: BackupFile.getSaveName(gameUrl: url),
//                            data: data
//                        )
//                    }
//                }
//            } else {
//                backupFile?.saveGame(ptr: ptr, backupLength: backupLength)
//            }
            backupFile?.saveGame(ptr: ptr, backupLength: backupLength)
        }
    }

    private func updateEmuInput(_ mapping: ButtonMapping, _ defaultButton: GBAButtonEvent, _ pressed: Bool) {
        if let emu = emulator {
            if let value = buttonEventDict[mapping] {
                emu.updateInput(value, pressed)
            } else {
                emu.updateInput(defaultButton, pressed)
            }
        }
    }

    private func addControllerEventListeners(gameController: GCController?) {
        if let controller = gameController?.extendedGamepad {
            controller.buttonB.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.b, .ButtonA, pressed)
            }
            controller.buttonA.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.a, .ButtonB, pressed)
            }
            controller.leftShoulder.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.leftShoulder, .ButtonL, pressed)
            }
            controller.rightShoulder.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.rightShoulder, .ButtonR, pressed)
            }
            controller.buttonMenu.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.menu, .Start, pressed)
            }
            controller.buttonOptions?.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.options, .Select, pressed)
            }
            controller.dpad.up.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.up, .Up, pressed)
            }
            controller.dpad.down.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.down, .Down, pressed)
            }
            controller.dpad.left.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.left, .Left, pressed)
            }
            controller.dpad.right.pressedChangedHandler = { (button, value, pressed) in
                updateEmuInput(.right, .Right, pressed)
            }
        }
    }

    private func resumeGame() {
        if let emu = emulatorCopy {
            isPaused = false

            // this is a hack, otherwise things won't work right when resuming game from home screen.
            // TODO: figure out why
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

    private func run() {
        let biosArr = Array(biosData!)
        let romArr = Array(romData!)

        var biosPtr: UnsafeBufferPointer<UInt8>!
        var romPtr: UnsafeBufferPointer<UInt8>!

        if emulator == nil {
            emulator = GBAEmulator()

            biosArr.withUnsafeBufferPointer { ptr in
                biosPtr = ptr
            }

            romArr.withUnsafeBufferPointer { ptr in
                romPtr = ptr
            }

            emulator!.load(romPtr)
            emulator!.loadBios(biosPtr)
        }

        isRunning = true

        audioManager = AudioManager()

        audioManager!.startAudio()

        if !isSoundOn {
            audioManager?.muteAudio()
        }

        if let emu = emulator, let gameUrl = gameUrl {
            backupFile = GBABackupFile(gameUrl: gameUrl, backupSize: Int(emu.backupFileSize()))
            if let ptr = backupFile!.createBackupFile() {
                emu.loadSave(ptr)
            }
        }


        workItem = DispatchWorkItem {
            mainGameLoop()
        }

        DispatchQueue.global().async(execute: workItem!)
    }

    private func mainGameLoop() {
        while true {
            if !isPaused {
                DispatchQueue.main.sync {
                    if let emu = emulator {
                        emu.stepFrame()

                        let pixels = emu.getPicturePtr()

                        if let image = graphicsParser.fromGBAPointer(ptr: pixels) {
                            self.image = image
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
                }
            }

            if !isRunning {
                break
            }
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
                VStack {
                    GBAScreenViewWrapper(
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
                        GBATouchControlsView(
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
                            isPaused: $isPaused
                        )
                    }
                    Spacer()
                }
            }
            .sheet(
                isPresented: $isMenuPresented
            ) {
                // TODO: implement save states and hold buttons
                GBAMenuView(
                    emulator: $emulator,
                    backupFile: $backupFile,
                    isRunning: $isRunning,
                    workItem: $workItem,
                    audioManager: $audioManager,
                    isMenuPresented: $isMenuPresented,
                    gameName: $gameName,
                    biosData: $biosData,
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

                if !isRunning {
                    run()
                    gameController = GameController(closure: { gameController in
                        addControllerEventListeners(gameController: gameController)
                    })
                } else {
                    resumeGame()
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
