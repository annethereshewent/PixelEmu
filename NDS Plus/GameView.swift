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
    
    @Environment(\.modelContext) private var context
    
    private let graphicsParser = GraphicsParser()
    
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
        
        if gameUrl != nil {
            if let game = Game.storeGame(
                data: romData!,
                url: gameUrl!,
                iconPtr: emulator!.getGameIconPointer()
            ) {
                context.insert(game)
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
                emu.updateInput(ButtonEvent.ButtonA, controller.buttonA.isPressed)
                emu.updateInput(ButtonEvent.ButtonB, controller.buttonB.isPressed)
                emu.updateInput(ButtonEvent.ButtonY, controller.buttonY.isPressed)
                emu.updateInput(ButtonEvent.ButtonX, controller.buttonX.isPressed)
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
    var body: some View {
        ZStack {
            Color.mint
            VStack {
                Spacer()
                Image(uiImage: topImage)
                    .resizable()
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * 1.5,
                        height: CGFloat(SCREEN_HEIGHT) * 1.5
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                Image(uiImage: bottomImage)
                    .resizable()
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * 1.5,
                        height: CGFloat(SCREEN_HEIGHT) * 1.5
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .onTapGesture() { location in
                        if location.x >= 0 && location.y >= 0 {
                            let x = UInt16(Float(location.x) / 1.5)
                            let y = UInt16(Float(location.y) / 1.5)
                            
                            emulator?.touchScreen(x, y)
                            
                            DispatchQueue.global().async(execute: DispatchWorkItem {
                                usleep(200)
                                DispatchQueue.main.sync() {
                                    emulator?.releaseScreen()
                                }
                            })
                        }
                        
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { value in
                                if value.location.x >= 0 && value.location.y >= 0 {
                                    let x = UInt16(Float(value.location.x) / 1.5)
                                    let y = UInt16(Float(value.location.y) / 1.5)
                                    emulator?.touchScreen(x, y)
                                }
                            }
                            .onEnded() { value in
                                if value.location.x >= 0 && value.location.y >= 0 {
                                    let x = UInt16(Float(value.location.x) / 1.5)
                                    let y = UInt16(Float(value.location.y) / 1.5)
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
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            self.run()
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}
