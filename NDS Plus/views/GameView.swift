//
//  GameView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/18/24.
//

import SwiftUI
import DSEmulatorMobile

struct GameView: View {
    @State private var topImage = UIImage()
    @State private var bottomImage = UIImage()
    @Binding var emulator: MobileEmulator?
    
    @State private var isRunning = false
    
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    
    @State private var gameController = GameController()
    @State private var workItem: DispatchWorkItem? = nil
    @State private var touch = false
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @Environment(\.modelContext) private var context
    @Environment(\.presentationMode) var presentationMode
    
    private let graphicsParser = GraphicsParser()

    @State private var buttons: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()
    @State private var controlPad: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()
    
    @State private var buttonStarted: [ButtonEvent:Bool] = [ButtonEvent:Bool]()
    
    @State private var gameName = ""
    
    @State private var backupFile: BackupFile? = nil
    
    @State private var debounceTimer: Timer? = nil
    
    private func initButtonState() {
        self.buttonStarted[ButtonEvent.Up] = false
        self.buttonStarted[ButtonEvent.Down] = false
        self.buttonStarted[ButtonEvent.Left] = false
        self.buttonStarted[ButtonEvent.Right] = false
        
        self.buttonStarted[ButtonEvent.ButtonA] = false
        self.buttonStarted[ButtonEvent.ButtonB] = false
        self.buttonStarted[ButtonEvent.ButtonY] = false
        self.buttonStarted[ButtonEvent.ButtonX] = false
        
        self.buttonStarted[ButtonEvent.ButtonL] = false
        self.buttonStarted[ButtonEvent.ButtonR] = false
        
        self.buttonStarted[ButtonEvent.Start] = false
        self.buttonStarted[ButtonEvent.Select] = false
    }
    
    private func checkSaves() {
        if emulator!.hasSaved() {
            emulator!.setSaved(false)
            debounceTimer?.invalidate()
            
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { _ in
                self.saveGame()
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
    
    private func run() {
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
                    backupFile = BackupFile(entry: entries[0], gameUrl: url)
                    if let data = backupFile!.createBackupFile() {
                        emulator!.setBackup(entries[0].saveType, entries[0].ramCapacity, data)
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
    
    private func handleControlPad(point: CGPoint) {
        self.handleInput(point: point, entries: controlPad)
    }
    
    private func handleInput(point: CGPoint, entries: [ButtonEvent:CGRect]) {
        if let emu = emulator {
            for entry in entries {
                if entry.value.contains(point) {
                    emu.updateInput(entry.key, true)
                } else {
                    emu.updateInput(entry.key, false)
                }
            }
        }
    }
    
    private func releaseControlPad() {
        if let emu = emulator {
            emu.updateInput(ButtonEvent.Up, false)
            emu.updateInput(ButtonEvent.Left, false)
            emu.updateInput(ButtonEvent.Right, false)
            emu.updateInput(ButtonEvent.Down, false)
        }
    }
    
    private func handleButtons(point: CGPoint) {
        self.handleInput(point: point, entries: buttons)
    }
    
    private func releaseButtons() {
        if let emu = emulator {
            emu.updateInput(ButtonEvent.ButtonA, false)
            emu.updateInput(ButtonEvent.ButtonB, false)
            emu.updateInput(ButtonEvent.ButtonY, false)
            emu.updateInput(ButtonEvent.ButtonX, false)
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
    
    private func checkForHapticFeedback(point: CGPoint) {
        for entry in buttons {
            if entry.value.contains(point) && !buttonStarted[entry.key]! {
                feedbackGenerator.impactOccurred()
                buttonStarted[entry.key] = true
                break
            }
        }
    }
    
    private func releaseHapticFeedback() {
        buttonStarted[ButtonEvent.ButtonA] = false
        buttonStarted[ButtonEvent.ButtonB] = false
        buttonStarted[ButtonEvent.ButtonY] = false
        buttonStarted[ButtonEvent.ButtonX] = false
    }
    
    var body: some View {
        ZStack {
            Color.mint
            VStack {
                Image(uiImage: topImage)
                    .resizable()
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * 1.36,
                        height: CGFloat(SCREEN_HEIGHT) * 1.36
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .padding(.top, 50)
                Image(uiImage: bottomImage)
                    .resizable()
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * 1.36,
                        height: CGFloat(SCREEN_HEIGHT) * 1.36
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { value in
                                if value.location.x >= 0 && value.location.y >= 0 {
                                    let x = UInt16(Float(value.location.x) / 1.36)
                                    let y = UInt16(Float(value.location.y) / 1.36)
                                    emulator?.touchScreen(x, y)
                                }
                            }
                            .onEnded() { value in
                                if value.location.x >= 0 && value.location.y >= 0 {
                                    let x = UInt16(Float(value.location.x) / 1.36)
                                    let y = UInt16(Float(value.location.y) / 1.36)
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
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image("L Button")
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        if !buttonStarted[ButtonEvent.ButtonL]! {
                                            feedbackGenerator.impactOccurred()
                                            buttonStarted[ButtonEvent.ButtonL] = true
                                        }
                                        emulator?.updateInput(ButtonEvent.ButtonL, true)
                                    }
                                    .onEnded() { result in
                                        buttonStarted[ButtonEvent.ButtonL] = false
                                        emulator?.updateInput(ButtonEvent.ButtonL, false)
                                    }
                            )
                        Spacer()
                        Spacer()
                        Spacer()
                        Image("R Button")
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        if !buttonStarted[ButtonEvent.ButtonR]! {
                                            feedbackGenerator.impactOccurred()
                                            buttonStarted[ButtonEvent.ButtonR] = true
                                        }
                                        emulator?.updateInput(ButtonEvent.ButtonR, true)
                                    }
                                    .onEnded() { result in
                                        buttonStarted[ButtonEvent.ButtonR] = false
                                        emulator?.updateInput(ButtonEvent.ButtonR, false)
                                    }
                            )
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Image("Control Pad")
                            .resizable()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            let frame = geometry.frame(in: .local)
                                            let up = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height / 3)
                                            let down = CGRect(x: frame.minX, y: (frame.maxY / 3) * 2, width: frame.width, height: frame.height / 3)
                                            let right = CGRect(x: (frame.maxX / 3) * 2, y: frame.minY, width: frame.width / 3, height: frame.height)
                                            let left = CGRect(x: frame.minX, y: frame.minY, width: frame.width / 3, height: frame.height)
                                            
                                            controlPad[ButtonEvent.Up] = up
                                            controlPad[ButtonEvent.Down] = down
                                            controlPad[ButtonEvent.Left] = left
                                            controlPad[ButtonEvent.Right] = right
                                        }
                                }
                            )
                            .frame(width: 150, height: 150)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        // you can use any of the control pad buttons here and it'll work ok
                                        // the choice to use up is arbitrary
                                        if !buttonStarted[ButtonEvent.Up]! {
                                            feedbackGenerator.impactOccurred()
                                            buttonStarted[ButtonEvent.Up] = true
                                        }
                                        self.handleControlPad(point: result.location)
                                    }
                                    .onEnded() { result in
                                        buttonStarted[ButtonEvent.Up] = false
                                        self.releaseControlPad()
                                    }
                            )
                        Spacer()
                        Spacer()
                        Image("Buttons")
                            .resizable()
                            .frame(width: 175, height: 175)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            let frame = geometry.frame(in: .local)

                                            let width = frame.maxY * 0.32
                                            let height = frame.maxY * 0.32
                                            
                                            let xButton = CGRect(x: frame.maxX * 0.35, y: frame.minY, width: width, height: height)
                                            let yButton  = CGRect(x: frame.minX, y: frame.maxY * 0.35, width: width, height: height)
                                            let aButton = CGRect(x: frame.maxY * 0.69, y: frame.maxY * 0.35, width: width, height: height)
                                            let bButton = CGRect(x: frame.maxX * 0.35, y: frame.maxY * 0.69, width: width, height: height)
                                            
                                            buttons[ButtonEvent.ButtonA] = aButton
                                            buttons[ButtonEvent.ButtonX] = xButton
                                            buttons[ButtonEvent.ButtonY] = yButton
                                            buttons[ButtonEvent.ButtonB] = bButton
                                        }
                                }
                            )
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        self.checkForHapticFeedback(point: result.location)
                                        self.handleButtons(point: result.location)
                                    }
                                    .onEnded() { result in
                                        self.releaseButtons()
                                        self.releaseHapticFeedback()
                                    }
                            )
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image("Home Button")
                                .resizable()
                                .frame(width:  40, height: 40)
                        }
                        Spacer()
                        Image("Select")
                            .resizable()
                            .frame(width: 72, height: 24)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        if !buttonStarted[ButtonEvent.Select]! {
                                            feedbackGenerator.impactOccurred()
                                            buttonStarted[ButtonEvent.Select] = true
                                        }
                                        emulator?.updateInput(ButtonEvent.Select, true)
                                    }
                                    .onEnded() { result in
                                        buttonStarted[ButtonEvent.Select] = false
                                        emulator?.updateInput(ButtonEvent.Select, false)
                                    }
                            )
                        Spacer()
                        Image("Start")
                            .resizable()
                            .frame(width: 72, height: 24)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        if !buttonStarted[ButtonEvent.Start]! {
                                            feedbackGenerator.impactOccurred()
                                            buttonStarted[ButtonEvent.Start] = true
                                        }
                                        emulator?.updateInput(ButtonEvent.Start, true)
                                    }
                                    .onEnded() { result in
                                        buttonStarted[ButtonEvent.Start] = false
                                        emulator?.updateInput(ButtonEvent.Start, false)
                                    }
                            )
                        Spacer()
                    }
                    Spacer()
                }

            }
        }
        .onAppear {
            self.initButtonState()
            self.run()
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .ignoresSafeArea(.all)
        .edgesIgnoringSafeArea(.all)
        .statusBarHidden()
}
}
