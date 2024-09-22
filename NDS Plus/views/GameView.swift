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
    
    @Environment(\.modelContext) private var context
    @Environment(\.presentationMode) var presentationMode
    
    private let graphicsParser = GraphicsParser()

    @State private var buttons: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()
    
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
    
    private func handleControlPad(point: CGPoint) {
        let upPressed = buttons[ButtonEvent.Up]?.contains(point) ?? false
        let downPressed = buttons[ButtonEvent.Down]?.contains(point) ?? false
        let leftPressed = buttons[ButtonEvent.Left]?.contains(point) ?? false
        let rightPressed = buttons[ButtonEvent.Right]?.contains(point) ?? false
        
        if let emu = emulator {
            emu.updateInput(ButtonEvent.Up, upPressed)
            emu.updateInput(ButtonEvent.Down, downPressed)
            emu.updateInput(ButtonEvent.Left, leftPressed)
            emu.updateInput(ButtonEvent.Right, rightPressed)
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
                Spacer()
                Image(uiImage: topImage)
                    .resizable()
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * 1.4,
                        height: CGFloat(SCREEN_HEIGHT) * 1.4
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                Image(uiImage: bottomImage)
                    .resizable()
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * 1.4,
                        height: CGFloat(SCREEN_HEIGHT) * 1.4
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .onTapGesture() { location in
                        if location.x >= 0 && location.y >= 0 {
                            let x = UInt16(Float(location.x) / 1.4)
                            let y = UInt16(Float(location.y) / 1.4)
                            
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
                                    let x = UInt16(Float(value.location.x) / 1.4)
                                    let y = UInt16(Float(value.location.y) / 1.4)
                                    emulator?.touchScreen(x, y)
                                }
                            }
                            .onEnded() { value in
                                if value.location.x >= 0 && value.location.y >= 0 {
                                    let x = UInt16(Float(value.location.x) / 1.4)
                                    let y = UInt16(Float(value.location.y) / 1.4)
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
                    HStack {
                        Spacer()
                        Image("L Button")
                            .onTapGesture { location in
                                print("you tapped the l button!")
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        print("you're holding the l button!")
                                    }
                                    .onEnded() { result in
                                        print("you stopped pressing the l button.")
                                    }
                            )
                        Spacer()
                        Spacer()
                        Spacer()
                        Image("R Button")
                            .onTapGesture { location in
                                print("you're pressing the r button!")
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        print("you're holding the r button!")
                                    }
                                    .onEnded() { result in
                                        print("you stopped pressing r button!")
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
                                            
                                            buttons[ButtonEvent.Up] = up
                                            buttons[ButtonEvent.Down] = down
                                            buttons[ButtonEvent.Left] = left
                                            buttons[ButtonEvent.Right] = right
                                        }
                                }
                            )
                            .frame(width: 150, height: 150)
                            .onTapGesture { location in
                                print("you tapped the control pad at \(location)")
                                self.handleControlPad(point: location)
                                
                                DispatchQueue.global().async(execute: DispatchWorkItem {
                                    usleep(200)
                                    DispatchQueue.main.sync {
                                        self.releaseControlPad()
                                    }
                                })
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        print("you pressed \(result.location) on control pad!")
                                        self.handleControlPad(point: result.location)
                                    }
                                    .onEnded() { result in
                                        self.releaseControlPad()
                                        print("you stopped pressing the control pad.")
                                    }
                            )
                        Spacer()
                        Spacer()
                        Image("Buttons")
                            .resizable()
                            .frame(width: 175, height: 175)
                            .onTapGesture { location in
                                print("you tapped the buttons at \(location)")
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        print("you pressed \(result.location) on buttons!")
                                    }
                                    .onEnded() { result in
                                        print("you stopped pressing buttons.")
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
                            .onTapGesture { location in
                                print("you tapped the select button")
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        print("you're holding the select button")
                                    }
                                    .onEnded() { result in
                                        print("you stopped pressing the select button")
                                    }
                            )
                        Spacer()
                        Image("Start")
                            .resizable()
                            .frame(width: 72, height: 24)
                            .onTapGesture { location in
                                print("you tapped the start button!")
                            }
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged() { result in
                                        print("you're holding the start button.")
                                    }
                                    .onEnded() { result in
                                        print("you stopped pressing the start button.")
                                    }
                            )
                        Spacer()
                    }
                    Spacer()
                }

            }
        }
        .coordinateSpace(name: "screen")
        .onAppear {
            self.run()
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .ignoresSafeArea(.all)
        .edgesIgnoringSafeArea(.all)
        .statusBarHidden()
}
}
