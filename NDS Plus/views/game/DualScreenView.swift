//
//  GameScreensView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/13/24.
//

import SwiftUI
import DSEmulatorMobile

struct DualScreenView: View {
    @Binding var gameController: GameController?
    private let rectangleImage = UIImage(named: "Rectangle")
    @Binding var topImage: CGImage?
    @Binding var bottomImage: CGImage?
    @Binding var emulator: MobileEmulator?
    @Binding var buttonStarted: [ButtonEvent:Bool]
    @Binding var audioManager: AudioManager?
    @Binding var isSoundOn: Bool
    @Binding var isHoldButtonsPresented: Bool
    @Binding var heldButtons: Set<ButtonEvent>

    private var screenRatio: Float {
        if gameController?.controller?.extendedGamepad == nil {
            SCREEN_RATIO
        } else {
            FULLSCREEN_RATIO
        }
    }
  
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var currentHoldButtons: String {
        var buttons: [String] = []
        for button in heldButtons {
            switch button {
            case .ButtonA:
                buttons.append("A")
            case .ButtonB:
                buttons.append("B")
            case .ButtonL:
                buttons.append("L")
            case .ButtonR:
                buttons.append("R")
            case .ButtonX:
                buttons.append("X")
            case .ButtonY:
                buttons.append("Y")
            case .Down:
                buttons.append("Down")
            case .Left:
                buttons.append("Left")
            case .Right:
                buttons.append("Right")
            case .Up:
                buttons.append("Up")
            case .Select:
                buttons.append("Select")
            case .Start:
                buttons.append("Start")
            default:
                break
            }
        }

        return "Current: \(buttons.joined(separator: ","))"
    }

    private var padding: CGFloat {
        if gameController?.controller?.extendedGamepad == nil {
            return 40.0
        }
        
        return 0.0
    }
    
    var body: some View {
        ZStack {
            if gameController?.controller?.extendedGamepad == nil {
                Image("Rectangle")
                    .resizable()
                    .frame(width: rectangleImage!.size.width * 1.05, height: rectangleImage!.size.height * 0.9 )
            }
            VStack(spacing: 0) {
                VStack{
                    if gameController?.controller?.extendedGamepad != nil {
                        Spacer()
                    }
                    ZStack {
                        GameScreenView(image: $topImage)
                            .frame(
                                width: CGFloat(SCREEN_WIDTH) * CGFloat(screenRatio),
                                height: CGFloat(SCREEN_HEIGHT) * CGFloat(screenRatio)
                            )
                        if isHoldButtonsPresented {
                            VStack {
                                Text("Hold buttons")
                                    .foregroundColor(Colors.accentColor)
                                    .font(.custom("Departure Mono", size: 24))
                                Text("Press buttons to hold down, then press confirm")
                                    .foregroundColor(Colors.primaryColor)
                                Text(currentHoldButtons)
                                    .foregroundColor(Colors.accentColor)
                                Button("Confirm") {
                                    isHoldButtonsPresented = false
                                    if let emu = emulator {
                                        emu.setPause(false)
                                    }
                                }
                                .foregroundColor(Colors.accentColor)
                                .border(.gray)
                                .cornerRadius(0.3)
                                .padding(.top, 20)
                            }
                            .background(Colors.backgroundColor)
                            .font(.custom("Departure Mono", size: 16))
                            .opacity(0.9)
                        }
                    }
                    GameScreenView(image: $bottomImage)
                        .frame(
                            width: CGFloat(SCREEN_WIDTH) * CGFloat(screenRatio),
                            height: CGFloat(SCREEN_HEIGHT) * CGFloat(screenRatio)
                        ) 
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged() { value in
                                    if value.location.x >= 0 &&
                                        value.location.y >= 0 &&
                                        value.location.x < CGFloat(SCREEN_WIDTH) * CGFloat(screenRatio) &&
                                        value.location.y < CGFloat(SCREEN_HEIGHT) * CGFloat(screenRatio)
                                    {
                                        let x = UInt16(Float(value.location.x) / screenRatio)
                                        let y = UInt16(Float(value.location.y) / screenRatio)
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
                                        let x = UInt16(Float(value.location.x) / screenRatio)
                                        let y = UInt16(Float(value.location.y) / screenRatio)
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
                    if gameController?.controller?.extendedGamepad != nil {
                        Spacer()
                    }
                }
                .padding(.top, padding)
                if gameController?.controller?.extendedGamepad == nil {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Image("L Button")
                                .resizable()
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
                                .frame(width: 110, height: 38.5)
                            Spacer()
                            Button {
                                if let manager = audioManager {
                                    feedbackGenerator.impactOccurred()
                                    manager.toggleAudio()
                                    
                                    isSoundOn = !manager.playerPaused

                                    let defaults = UserDefaults.standard
                                    
                                    defaults.setValue(isSoundOn, forKey: "isSoundOn")
                                }
                            } label: {
                                Image("Volume Button")
                                    .resizable()
                                    .frame(width: 55, height: 33)
                            }
                            Spacer()
                            Image("R Button")
                                .resizable()
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
                                .frame(width: 110, height: 38.5)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
