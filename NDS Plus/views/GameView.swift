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
    @State private var topImage = UIImage()
    @State private var bottomImage = UIImage()
    @Binding var emulator: MobileEmulator?
    
    @State private var isRunning = false
    
    private let SCREEN_RATIO: Float = 1.36
    
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    @Binding var user: GIDGoogleUser?
    
    @State private var workItem: DispatchWorkItem? = nil
    @State private var cloudService: CloudService? = nil
    
    @Environment(\.modelContext) private var context
    
    
    private let graphicsParser = GraphicsParser()
    
    @State private var gameName = ""
    
    @State private var backupFile: BackupFile? = nil
    
    @State private var debounceTimer: Timer? = nil
    
    @State private var gameController = GameController()
    
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
        let ptr = emulator!.backupPointer();
        
        let buffer = UnsafeBufferPointer(start: ptr, count: Int(emulator!.backupLength()))
        
        let data = Data(buffer)
        
        if let saveUrl = backupFile?.saveUrl {
            do {
                try data.write(to: saveUrl)
            } catch {
                print(error)
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
            
            let gameCode = emulator!.getGameCode()
            
            if let entries = GameEntry.decodeGameDb() {
                let entries = entries.filter { $0.gameCode == gameCode }
                if entries.count > 0 {
                    if let user = user {
                        self.cloudService = CloudService(user: user)
                        if let url = gameUrl {
                            if let saveData = await self.cloudService!.getSave(saveName: BackupFile.getSaveName(gameUrl: url)) {
                                let ptr = BackupFile.getPointer(saveData)
                                emulator!.setBackup(entries[0].saveType, entries[0].ramCapacity, ptr)
                            }
                            
                        }
                    } else {
                        backupFile = BackupFile(entry: entries[0], gameUrl: url)
                        if let data = backupFile!.createBackupFile() {
                            emulator!.setBackup(entries[0].saveType, entries[0].ramCapacity, data)
                        }
                    }
                }
            }
        }
        
        isRunning = true
        
        workItem = DispatchWorkItem {
            if let emu = emulator {
                while true {
                    DispatchQueue.main.sync {
                        emu.stepFrame()
                        
                        let aPixels = emu.getEngineAPicturePointer()
                        
                        var imageA = UIImage()
                        var imageB = UIImage()
                        
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
    
    var body: some View {
        ZStack {
            Color.mint
            VStack {
                Image(uiImage: topImage)
                    .resizable()
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * CGFloat(SCREEN_RATIO),
                        height: CGFloat(SCREEN_HEIGHT) * CGFloat(SCREEN_RATIO)
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .padding(.top, 50)
                Image(uiImage: bottomImage)
                    .resizable()
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * CGFloat(SCREEN_RATIO),
                        height: CGFloat(SCREEN_HEIGHT) * CGFloat(SCREEN_RATIO)
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { value in
                                if value.location.x >= 0 && value.location.y >= 0 {
                                    let x = UInt16(Float(value.location.x) / SCREEN_RATIO)
                                    let y = UInt16(Float(value.location.y) / SCREEN_RATIO)
                                    emulator?.touchScreen(x, y)
                                }
                            }
                            .onEnded() { value in
                                if value.location.x >= 0 && value.location.y >= 0 {
                                    let x = UInt16(Float(value.location.x) / SCREEN_RATIO)
                                    let y = UInt16(Float(value.location.y) / SCREEN_RATIO)
                                    emulator?.touchScreen(x, y)
                                    DispatchQueue.global().async(execute: DispatchWorkItem {
                                        usleep(200)
                                        DispatchQueue.main.sync() {
                                            emulator?.releaseScreen()
                                        }
                                    })
                                }
                                
                            }
                    )
                TouchControlsView(emulator: $emulator)
            }
        }
        .onAppear {
            Task {
                await self.run()
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .ignoresSafeArea(.all)
        .edgesIgnoringSafeArea(.all)
        .statusBarHidden()
    }
}
