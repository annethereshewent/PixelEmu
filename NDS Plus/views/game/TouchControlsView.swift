//
//  TouchControlsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import SwiftUI
import DSEmulatorMobile

struct TouchControlsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var emulator: MobileEmulator?
    @Binding var audioManager: AudioManager?
    @Binding var workItem: DispatchWorkItem?
    @Binding var isRunning: Bool
    @Binding var buttonStarted: [ButtonEvent:Bool]
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var gameName: String
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @State private var buttons: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()
    @State private var controlPad: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()    
    @State private var buttonsMisc: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()
    @State private var isMenuPresented = false

    
    private func releaseHapticFeedback() {
        buttonStarted[ButtonEvent.ButtonA] = false
        buttonStarted[ButtonEvent.ButtonB] = false
        buttonStarted[ButtonEvent.ButtonY] = false
        buttonStarted[ButtonEvent.ButtonX] = false
    }
    
    private func checkForHapticFeedback(point: CGPoint, entries: [ButtonEvent:CGRect]) {
        for entry in entries {
            if entry.value.contains(point) && !buttonStarted[entry.key]! {
                feedbackGenerator.impactOccurred()
                buttonStarted[entry.key] = true
                break
            }
        }
    }
    
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
        
        self.buttonStarted[ButtonEvent.ButtonHome] = false
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
    
    private func handleMiscButtons(point: CGPoint) {
        for entry in buttonsMisc {
            if entry.value.contains(point) {
                if entry.key != ButtonEvent.ButtonHome {
                    if let emu = emulator {
                        emu.updateInput(entry.key, true)
                    }
                } else {
                    emulator = nil
                    isRunning = false
                    workItem?.cancel()
                    workItem = nil
                    
                    audioManager?.isRunning = false
                    
                    presentationMode.wrappedValue.dismiss()
                    break
                }
            } else if entry.key != ButtonEvent.ButtonHome {
                if let emu = emulator {
                    emu.updateInput(entry.key, false)
                }
            }
        }
        self.handleInput(point: point, entries: buttonsMisc)
    }

    private func releaseMiscButtons() {
        if let emu = emulator {
            emu.updateInput(ButtonEvent.Start, false)
            emu.updateInput(ButtonEvent.Select, false)
        }
    }
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image("Control Pad")
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
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { result in
                                // you can use any of the control pad buttons here and it'll work ok
                                // the choice to use up is arbitrary
                                if !buttonStarted[ButtonEvent.Up]! {
                                    feedbackGenerator.impactOccurred()
                                    buttonStarted[ButtonEvent.Up] = true
                                }
                                handleControlPad(point: result.location)
                            }
                            .onEnded() { result in
                                buttonStarted[ButtonEvent.Up] = false
                                releaseControlPad()
                            }
                    )
                Spacer()
                VStack {
                    Image("Buttons Misc")
                        .padding(.bottom, 10)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged() { result in
                                    checkForHapticFeedback(point: result.location, entries: buttonsMisc)
                                    handleMiscButtons(point: result.location)
                                }
                                .onEnded() { result in
                                    buttonStarted[ButtonEvent.Start] = false
                                    buttonStarted[ButtonEvent.Select] = false
                                    buttonStarted[ButtonEvent.ButtonHome] = false
                                    
                                    releaseMiscButtons()
                                }
                        )
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        let frame = geometry.frame(in: .local)
                                        
                                        // below numbers were gotten by dividing the heights of
                                        // buttons with the height of the entire button's image
                                        let width = frame.width
                                        let height = frame.height * (16.0 / 71.33333333333)
                                        
                                        let selectY = frame.maxY * (28 / 71.33333333333333)
                                        let homeY = frame.maxY * (54.0 / 71.33333333333333)
                                    
                                        let startButton = CGRect(x: 0, y: 0, width: width, height: height)
                                        let selectButton = CGRect(x: 0, y: selectY, width: width, height: height)
                                        let homeButton = CGRect(x:0, y: homeY, width: width, height: height)
                                        
                                        buttonsMisc[ButtonEvent.Start] = startButton
                                        buttonsMisc[ButtonEvent.Select] = selectButton
                                        buttonsMisc[ButtonEvent.ButtonHome] = homeButton
                                    }
                            }
                        )
                    Button() {
                        isMenuPresented = !isMenuPresented
                        if let emu = emulator {
                            emu.setPause(isMenuPresented)
                        }
                    } label: {
                        Image("Red Button")
                    }
                }
                Spacer()
                Image("Buttons")
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
                                checkForHapticFeedback(point: result.location, entries: buttons)
                                handleButtons(point: result.location)
                            }
                            .onEnded() { result in
                                releaseButtons()
                                releaseHapticFeedback()
                            }
                    )
                Spacer()
            }
            Spacer()
        }
        .onAppear {
            initButtonState()
        }
        .sheet(
            isPresented: $isMenuPresented
        ) {
            HStack {
                Spacer()
                Button() {
                    if let emu = emulator {
                        let dataPtr = emu.createSaveState()
                        let compressedLength = emu.compressedLength()
                        
                        let unsafeBufferPtr = UnsafeBufferPointer(start: dataPtr, count: Int(compressedLength))
                        
                        let data = Data(unsafeBufferPtr)
                        
                        do {
                            var location = try FileManager.default.url(
                                 for: .applicationSupportDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true
                             )
                            
                            location.appendPathComponent("save_states")
                            
                            if !FileManager.default.fileExists(atPath: location.path) {
                                try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
                            }
                            
                            let gameFolder = gameName.replacing(".nds", with: "")
                            
                            location.appendPathComponent(gameFolder)
                            
                            if !FileManager.default.fileExists(atPath: location.path) {
                                try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
                            }
                            
                            location.appendPathComponent("state_1.save")
                            
                            try data.write(to: location)
                        } catch {
                            print(error)
                        }
                        isMenuPresented = false
                    }
                } label: {
                    VStack {
                        Image(systemName: "tray.and.arrow.up")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Save state")
                            .font(.callout)
                    }
                }
                Spacer()
                Button() {
                    do {
                        var location = try FileManager.default.url(
                            for: .applicationSupportDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true
                        )
                        
                        location.appendPathComponent("save_states")
                        
                        if !FileManager.default.fileExists(atPath: location.path) {
                            try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
                        }
                        
                        let gameFolder = gameName.replacing(".nds", with: "")
                        
                        location.appendPathComponent(gameFolder)
                        
                        if !FileManager.default.fileExists(atPath: location.path) {
                            try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
                        }
                        
                        location.appendPathComponent("state_1.save")
                        
                        if let data = try? Array(Data(contentsOf: location)) {
                            if let emu = emulator {
                                var dataPtr: UnsafeBufferPointer<UInt8>!
                                data.withUnsafeBufferPointer { ptr in
                                    dataPtr = ptr
                                }
                                
                                if let bios7 = bios7Data, let bios9 = bios9Data, let rom = romData {
                                    var bios7Ptr: UnsafeBufferPointer<UInt8>!
                                    var bios9Ptr: UnsafeBufferPointer<UInt8>!
                                    var romPtr: UnsafeBufferPointer<UInt8>!
                                    
                                    let bios7Arr = Array(bios7)
                                    
                                    bios7Arr.withUnsafeBufferPointer { ptr in
                                        bios7Ptr = ptr
                                    }
                                    
                                    let bios9Arr = Array(bios9)
                                    
                                    bios9Arr.withUnsafeBufferPointer { ptr in
                                        bios9Ptr = ptr
                                    }
                                    
                                    let romArr = Array(rom)
                                    
                                    romArr.withUnsafeBufferPointer { ptr in
                                        romPtr = ptr
                                    }
                                    
                                    emu.loadSaveState(dataPtr)
                                    emu.reloadBios(bios7Ptr, bios9Ptr)
                                    
                                    if let firmwareData = firmwareData {
                                        var firmwarePtr: UnsafeBufferPointer<UInt8>!
                                        let firmwareArr = Array(firmwareData)
                                        
                                        firmwareArr.withUnsafeBufferPointer { ptr in
                                            firmwarePtr = ptr
                                        }
                                        
                                        emu.reloadFirmware(firmwarePtr)
                                    } else {
                                        emu.hleFirmware()
                                    }
                                    emu.reloadRom(romPtr)
                                }
                                isMenuPresented = false
                            }
                        } else {
                            isMenuPresented = false
                        }
                    } catch {
                        print(error)
                    }
                } label: {
                    VStack {
                        Image(systemName: "tray.and.arrow.down")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Load state")
                            .font(.callout)
                    }
                    
                }
                Spacer()
                Button() {
                    isMenuPresented = false
                } label: {
                    VStack {
                        Image(systemName: "play")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Resume game")
                            .font(.callout)
                    }
                }
                
                Spacer()
            }
            .onDisappear() {
                if let emu = emulator {
                    emu.setPause(false)
                }
            }
            .presentationDetents([.height(150)])
        }
    }
}
