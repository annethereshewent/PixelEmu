//
//  GameView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/18/24.
//

import SwiftUI
import DSEmulatorMobile
import GoogleSignIn

struct GameView: View {
    @State private var topImage: CGImage?
    @State private var bottomImage: CGImage?
    @State private var gameName = ""
    @State private var backupFile: BackupFile? = nil
    @State private var debounceTimer: Timer? = nil
    @State private var gameController = GameController()
    @State private var audioPlayer: AudioPlayer? = nil
    @State private var isRunning = false
    @State private var workItem: DispatchWorkItem? = nil
    @State private var loading = false
    
    @Binding var emulator: MobileEmulator?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    @Binding var user: GIDGoogleUser?
    
    @Binding var cloudService: CloudService?
    
    @Environment(\.modelContext) private var context
    
    private let graphicsParser = GraphicsParser()
    
    
    
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
    
    private func handleInput() {
        if let controller = self.gameController.controller.extendedGamepad {
            if let emu = emulator {
                emu.updateInput(ButtonEvent.ButtonA, controller.buttonB.isPressed)
                emu.updateInput(ButtonEvent.ButtonB, controller.buttonA.isPressed)
                emu.updateInput(ButtonEvent.ButtonY, controller.buttonX.isPressed)
                emu.updateInput(ButtonEvent.ButtonX, controller.buttonY.isPressed)
                emu.updateInput(ButtonEvent.ButtonL, controller.leftShoulder.isPressed)
                emu.updateInput(ButtonEvent.ButtonR, controller.rightShoulder.isPressed)
                emu.updateInput(ButtonEvent.Start, controller.buttonMenu.isPressed)
                emu.updateInput(
                    ButtonEvent.Select,
                    controller.buttonOptions?.isPressed ?? false
                )
                emu.updateInput(ButtonEvent.Up, controller.dpad.up.isPressed)
                emu.updateInput(ButtonEvent.Down, controller.dpad.down.isPressed)
                emu.updateInput(ButtonEvent.Left, controller.dpad.left.isPressed)
                emu.updateInput(ButtonEvent.Right, controller.dpad.right.isPressed)
            }
            
        }
    }
    
    private func run() async {
        let bios7Arr: [UInt8] = Array(bios7Data!)
        let bios9Arr: [UInt8] = Array(bios9Data!)
        let firmwareArr: [UInt8] = Array(firmwareData!)
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
            
            self.audioPlayer = AudioPlayer()
            
            workItem = DispatchWorkItem {
                if let emu = emulator {
                    while true {
                        DispatchQueue.main.sync {
                            emu.stepFrame()
                            
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
                            
                            let bufferPtr = UnsafeBufferPointer(start: audioBufferPtr, count: Int(audioBufferLength))
                            
                            self.audioPlayer?.updateBuffer(bufferPtr: bufferPtr)
                            
                            self.handleInput()
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
            Color.mint
            VStack {
                GameScreenView(image: $topImage)
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * CGFloat(SCREEN_RATIO),
                        height: CGFloat(SCREEN_HEIGHT) * CGFloat(SCREEN_RATIO)
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .padding(.top, 50)
                GameScreenView(image: $bottomImage)
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * CGFloat(SCREEN_RATIO),
                        height: CGFloat(SCREEN_HEIGHT) * CGFloat(SCREEN_RATIO)
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { value in
                                if value.location.x >= 0 && 
                                    value.location.y >= 0 &&
                                    value.location.x < CGFloat(SCREEN_WIDTH) * CGFloat(SCREEN_RATIO) &&
                                    value.location.y < CGFloat(SCREEN_HEIGHT) * CGFloat(SCREEN_RATIO)
                                {
                                    let x = UInt16(Float(value.location.x) / SCREEN_RATIO)
                                    let y = UInt16(Float(value.location.y) / SCREEN_RATIO)
                                    emulator?.touchScreen(x, y)
                                } else {
                                    emulator?.releaseScreen()
                                }
                            }
                            .onEnded() { value in
                                if value.location.x >= 0 &&
                                    value.location.y >= 0 &&
                                    value.location.x < CGFloat(SCREEN_WIDTH) &&
                                    value.location.y < CGFloat(SCREEN_HEIGHT)
                                {
                                    let x = UInt16(Float(value.location.x) / SCREEN_RATIO)
                                    let y = UInt16(Float(value.location.y) / SCREEN_RATIO)
                                    emulator?.touchScreen(x, y)
                                    DispatchQueue.global().async(execute: DispatchWorkItem {
                                        usleep(200)
                                        DispatchQueue.main.sync() {
                                            emulator?.releaseScreen()
                                        }
                                    })
                                } else {
                                    emulator?.releaseScreen()
                                }
                                
                            }
                    )
                TouchControlsView(
                    emulator: $emulator,
                    workItem: $workItem,
                    isRunning: $isRunning
                )
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            Task {
                await self.run()
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .ignoresSafeArea(.all)
        .edgesIgnoringSafeArea(.all)
        .statusBarHidden()
    }
}
