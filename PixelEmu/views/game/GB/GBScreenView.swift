//
//  GBScreenView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 11/29/24.
//

import SwiftUI
import GBAEmulatorMobile

struct GBScreenView: View {
    let gameType: GameType
    @Binding var gameController: GameController?
    @Binding var image: CGImage?
    @Binding var isHoldButtonsPresented: Bool
    @Binding var themeColor: Color
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var heldButtons: Set<PressedButton>

    @EnvironmentObject var orientationInfo: OrientationInfo

    private var screenRatio: Float {
        switch orientationInfo.orientation {
        case .portrait:
            if gameController?.controller?.extendedGamepad == nil {
                return gameType == .gba ? GBA_SCREEN_RATIO : GBC_SCREEN_RATIO
            }

            return gameType == .gba ? GBA_FULLSCREEN_RATIO : GBC_SCREEN_RATIO
        case .landscape:
            if gameController?.controller?.extendedGamepad == nil {
                return gameType == .gba ? GBA_LANDSCAPE_RATIO : GBC_LANDSCAPE_RATIO
            }

            return gameType == .gba ? GBA_LANDSCAPE_FULLSCREEN_RATIO : GBC_LANDSCAPE_FULLSCREEN_RATIO
        }

    }

    private var screenWidth: CGFloat {
        if gameType == .gba {
            return CGFloat(GBA_SCREEN_WIDTH)
        }

        return CGFloat(GBC_SCREEN_WIDTH) * 1.3
    }

    private var screenHeight: CGFloat {
        if gameType == .gba {
            return CGFloat(GBA_SCREEN_HEIGHT)
        }

        return CGFloat(GBC_SCREEN_HEIGHT) * 1.3
    }

    private var currentHoldButtons: String {
        var buttons: [String] = []
        for button in heldButtons {
            switch button {
            case .ButtonCircle:
                buttons.append("A")
            case .ButtonCross:
                buttons.append("B")
            case .ButtonL:
                buttons.append("L")
            case .ButtonR:
                buttons.append("R")
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
            default: ()
            }
        }

        return "Current: \(buttons.joined(separator: ","))"
    }

    var body: some View {
        if gameController?.controller?.extendedGamepad != nil {
            Spacer()
        }
        ZStack {
            GameScreenView(image: $image)
                .frame(
                    width: CGFloat(screenWidth) * CGFloat(screenRatio),
                    height: CGFloat(screenHeight) * CGFloat(screenRatio)
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
                            emu.setPaused(false)
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
        if gameController?.controller?.extendedGamepad != nil {
            Spacer()
            Spacer()
            Spacer()
        }
    }
}
