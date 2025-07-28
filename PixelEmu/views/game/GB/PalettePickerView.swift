//
//  PalettePickerView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/27/25.
//

import SwiftUI

class Palette: Identifiable {
    init(name: String, primaryColor: Color) {
        self.name = name
        self.primaryColor = primaryColor
    }
    var name: String
    var primaryColor: Color
}

let PALETTES = [
    Palette(name: "Classic green", primaryColor: Color(red: 0x8b / 0xff, green: 0xac / 0xff, blue: 0xf / 0xff)),
    Palette(name: "Grayscale", primaryColor: Color(red: 0xaa / 0xff, green: 0xaa / 0xff, blue: 0xaa / 0xff)),
    Palette(name: "Solarized", primaryColor: Color(red: 0x83 / 0xff, green: 0x94 / 0xff, blue: 0x96 / 0xff)),
    Palette(name: "Maverick", primaryColor: Color(red: 0x86 / 0xff, green: 0xc0 / 0xff, blue: 0x6c / 0xff)),
    Palette(name: "Oceanic", primaryColor: Color(red: 0x7f / 0xff, green: 0xdb / 0xff, blue: 0xff / 0xff)),
    Palette(name: "Burnt peach", primaryColor: Color(red: 0xd9 / 0xff, green: 0x72 / 0xff, blue: 0x5e / 0xff)),
    Palette(name: "Grape soda", primaryColor: Color(red: 0x8e / 0xff, green: 0x7c / 0xff, blue: 0xc3 / 0xff)),
    Palette(name: "Strawberry milk", primaryColor: Color(red: 0xff / 0xff, green: 0xc2 / 0xff, blue: 0xd7 / 0xff)),
    Palette(name: "Witching hour", primaryColor: Color(red: 0x94 / 0xff, green: 0x7e / 0xff, blue: 0xc3 / 0xff)),
    Palette(name: "Void dream", primaryColor: Color(red: 0x81 / 0xff, green: 0xd4 / 0xff, blue: 0xfa / 0xff))
]


struct PalettePickerView: View {
    @Binding var themeColor: Color
    @Binding var emulator: EmulatorWrapper?
    @Binding var isPresented: Bool
    @Binding var isMenuPresented: Bool

    var body: some View {
        VStack {
            Text("Palette picker")
                .font(.custom("Departure Mono", size: 16))
                .foregroundColor(themeColor)
            Spacer()
            ForEach(Array(PALETTES.enumerated()), id: \.offset) { index, palette in
                Button {
                    try! emulator!.setPalette(UInt(index))
                    emulator!.setPaused(false)
                    isPresented = false
                    isMenuPresented = false

                    let defaults = UserDefaults.standard

                    defaults.set(index, forKey: "currentPalette")
                } label: {
                    HStack {
                        Text(palette.name)
                            .padding(.leading, 40)
                        Spacer()
                        Circle()
                            .foregroundColor(palette.primaryColor)
                            .padding(.trailing, 40)
                    }
                }
                .font(.custom("Departure Mono", size: 14))
                .foregroundColor(Colors.primaryColor)
            }
        }
    }
}
