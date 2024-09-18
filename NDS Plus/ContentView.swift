//
//  ContentView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI
import UniformTypeIdentifiers
import GameController
import DSEmulatorMobile

struct ContentView: View {
    @State private var showSettings = false
    @State private var showRomDialog = false

    @State private var bios7Data: Data? = nil
    @State private var bios9Data: Data? = nil
    @State private var firmwareData: Data? = nil
    @State private var romData: Data? = nil
    @State private var topImage: UIImage = UIImage()
    @State private var bottomImage: UIImage = UIImage()
    
    @State private var workItem: DispatchWorkItem? = nil
    @State private var isRunning = false
    
    @State private var gameController = GameController()
    
    
    let graphicsParser = GraphicsParser()
    
    @State private var emulator: MobileEmulator? = nil
    
    let ndsType = UTType(filenameExtension: "nds", conformingTo: .data)
    
    var buttonDisabled: Bool {
        return bios7Data == nil || bios9Data == nil || firmwareData == nil
    }
    
    var buttonColor: Color {
        switch colorScheme {
        case .dark:
            return buttonDisabled ? Color.secondary : Color.white
        case .light:
            return buttonDisabled ? Color.gray : Color.cyan
        default:
            return buttonDisabled ? Color.gray : Color.cyan
        }
    }
    
    private func run(
        bios7Ptr: UnsafeBufferPointer<UInt8>,
        bios9Ptr: UnsafeBufferPointer<UInt8>,
        firmwarePtr: UnsafeBufferPointer<UInt8>,
        romPtr: UnsafeBufferPointer<UInt8>
    ) {
        emulator = MobileEmulator(
            bios7Ptr,
            bios9Ptr,
            firmwarePtr,
            romPtr
        )
        
        isRunning = true
        
        workItem = DispatchWorkItem {
            if let emu = emulator {
                while true {
                    DispatchQueue.main.sync {
                        emu.step_frame()
                        
                        let aPixels = emu.get_engine_a_picture_pointer()
                        
                        var imageA = UIImage()
                        var imageB = UIImage()
                        
                        if let image = graphicsParser.fromPointer(ptr: aPixels) {
                            imageA = image
                        }
                        
                        let bPixels = emu.get_engine_b_picture_pointer()
                        
                        if let image = graphicsParser.fromPointer(ptr: bPixels) {
                            imageB = image
                            
                        }
                        
                        if emu.is_top_a() {
                            topImage = imageA
                            bottomImage = imageB
                        } else {
                            topImage = imageB
                            bottomImage = imageA
                        }
                        
                        self.handleInput()
                    }
                    
                    if !isRunning {
                        break
                    }
                }
            }
            
        }
        
        DispatchQueue.global().async(execute: workItem!)
    }
    
    private func handleInput() {
        if let controller = self.gameController.controller.extendedGamepad {
            if let emu = emulator {
                emu.update_input(ButtonEvent.ButtonA, controller.buttonA.isPressed)
                emu.update_input(ButtonEvent.ButtonB, controller.buttonB.isPressed)
                emu.update_input(ButtonEvent.ButtonY, controller.buttonY.isPressed)
                emu.update_input(ButtonEvent.ButtonX, controller.buttonX.isPressed)
                emu.update_input(ButtonEvent.ButtonL, controller.leftShoulder.isPressed)
                emu.update_input(ButtonEvent.ButtonR, controller.rightShoulder.isPressed)
                emu.update_input(ButtonEvent.Start, controller.buttonMenu.isPressed)
                emu.update_input(
                    ButtonEvent.Select,
                    controller.buttonOptions?.isPressed ?? false
                )
                emu.update_input(ButtonEvent.Up, controller.dpad.up.isPressed)
                emu.update_input(ButtonEvent.Down, controller.dpad.down.isPressed)
                emu.update_input(ButtonEvent.Left, controller.dpad.left.isPressed)
                emu.update_input(ButtonEvent.Right, controller.dpad.right.isPressed)
            }
            
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("", systemImage: "gear") {
                    showSettings.toggle()
                }
                .font(.title)
                .frame(alignment: .trailing)
                .foregroundColor(.indigo)
                .padding(.trailing)

            }
            .sheet(isPresented: $showSettings) {
                VStack {
                    SettingsView(
                        bios7Data: $bios7Data,
                        bios9Data: $bios9Data,
                        firmwareData: $firmwareData
                    )
                }
                .background(colorScheme == .dark ? Color.black : Color.white)
            }
            HStack {
                Text("NDS Plus")
                    .font(.largeTitle)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(alignment: .center)
            }
            // Spacer()
            Image(uiImage: topImage)
                .resizable()
                .frame(
                    width: CGFloat(SCREEN_WIDTH) * 1.25,
                    height: CGFloat(SCREEN_HEIGHT) * 1.25
                )
            Image(uiImage: bottomImage)
                .resizable()
                .frame(
                    width: CGFloat(SCREEN_WIDTH) * 1.25,
                    height: CGFloat(SCREEN_HEIGHT) * 1.25
                )
                .onTapGesture() { location in
                    if location.x >= 0 && location.y >= 0 {
                        let x = UInt16(Float(location.x) / 1.25)
                        let y = UInt16(Float(location.y) / 1.25)
                    
                        emulator?.touch_screen(x, y)
                        
                        DispatchQueue.global().async(execute: DispatchWorkItem {
                            usleep(200)
                            DispatchQueue.main.sync() {
                                emulator?.release_screen()
                            }
                        })
                    }
                   
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged() { value in
                            if value.location.x >= 0 && value.location.y >= 0 {
                                let x = UInt16(Float(value.location.x) / 1.25)
                                let y = UInt16(Float(value.location.y) / 1.25)
                                emulator?.touch_screen(x, y)
                            }
                        }
                        .onEnded() { value in
                            if value.location.x >= 0 && value.location.y >= 0 {
                                let x = UInt16(Float(value.location.x) / 1.25)
                                let y = UInt16(Float(value.location.y) / 1.25)
                                emulator?.touch_screen(x, y)
                                DispatchQueue.global().async(execute: DispatchWorkItem {
                                    usleep(200)
                                    DispatchQueue.main.sync() {
                                        emulator?.release_screen()
                                    }
                                })
                            }
                            
                        }
                )
                
            Spacer()
            HStack {
                Button("Load Game", systemImage: "square.and.arrow.up.circle") {
                    emulator = nil
                    workItem?.cancel()
                    isRunning = false
                    
                    workItem = nil
                    
                    showRomDialog = true
                }
                .foregroundColor(buttonColor)
                .disabled(buttonDisabled)
                .font(.title)
            }
            Spacer()
        }
        .fileImporter(
            isPresented: $showRomDialog,
            allowedContentTypes: [ndsType.unsafelyUnwrapped]
        ) { result in
            if let url = try? result.get() {
                if url.startAccessingSecurityScopedResource() {
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    if let data = try? Data(contentsOf: url) {

                        romData = data
                        
                        if bios7Data != nil && bios9Data != nil && firmwareData != nil {
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
                            
                            // we finally have an emulator!
                            self.run(
                                bios7Ptr: bios7Ptr!,
                                bios9Ptr: bios9Ptr!,
                                firmwarePtr: firmwarePtr!,
                                romPtr: romPtr!
                            )
                        }
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white )
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
