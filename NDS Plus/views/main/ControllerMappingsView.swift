//
//  ControllerMappingsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/1/24.
//

import SwiftUI

struct ControllerMappingsView: View {
    @Binding var themeColor: Color
    var body: some View {
        List {
            Section(header: Text("Joypad mappings").foregroundColor(Colors.primaryColor)) {
                Button("Up") {

                }
                Button("Down") {

                }
                Button("Left") {

                }
                Button("Right") {

                }
                Button("A button") {

                }
                Button("B button") {

                }
                Button("Y button") {

                }
                Button("X button") {
                    
                }
                Button("L button") {

                }
                Button("R button") {

                }
            }
            Section(header: Text("Hotkey mappings").foregroundColor(Colors.primaryColor)) {
                Button("Control stick mode (SM64 DS only)") {

                }
                Button("Quick load") {

                }
                Button("Quick save") {

                }
            }

        }
        .font(.custom("Departure Mono", size: 18))
        .foregroundColor(themeColor)
    }
}
