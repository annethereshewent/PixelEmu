//
//  DualScreenView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/28/24.
//

import SwiftUI
import DSEmulatorMobile

struct DualScreenView: View {
    @Binding var gameController: GameController?
    @Binding var topImage: CGImage?
    @Binding var bottomImage: CGImage?
    @Binding var isHoldButtonsPresented: Bool
    @Binding var themeColor: Color
    @Binding var emulator: MobileEmulator?
    @Binding var heldButtons: Set<ButtonEvent>

    @EnvironmentObject var orientationInfo: OrientationInfo

    private var screenRatio: Float {
        switch orientationInfo.orientation {
        case .portrait:
            if gameController?.controller?.extendedGamepad == nil {
                return SCREEN_RATIO
            }

            return FULLSCREEN_RATIO
        case .landscape:
            if gameController?.controller?.extendedGamepad == nil {
                return LANDSCAPE_RATIO
            }

            return LANDSCAPE_FULLSCREEN_RATIO
        }

    }

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

    var body: some View {
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
                        .foregroundColor(themeColor)
                        .font(.custom("Departure Mono", size: 24))
                    Text("Press buttons to hold down, then press confirm")
                        .foregroundColor(Colors.primaryColor)
                    Text(currentHoldButtons)
                        .foregroundColor(themeColor)
                    Button("Confirm") {
                        isHoldButtonsPresented = false
                        if let emu = emulator {
                            emu.setPause(false)
                        }
                    }
                    .foregroundColor(themeColor)
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
}
