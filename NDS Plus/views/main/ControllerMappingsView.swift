//
//  ControllerMappingsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/1/24.
//

import SwiftUI
import DSEmulatorMobile

struct ControllerMappingsView: View {
    @Binding var themeColor: Color
    @Binding var isPresented: Bool

    private var buttonMappings: [ButtonEvent:String] {
        return [:]
    }
    var body: some View {
        VStack {
            List {
                Section(header: Text("Joypad mappings").foregroundColor(Colors.primaryColor)) {
                    Button {

                    } label: {
                        HStack {
                            Text("Up")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Up] ?? "Up")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("Down")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Down] ?? "Down")
                                .foregroundColor(Colors.primaryColor)

                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("Left")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Left] ?? "Left")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("Right")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Right] ?? "Right")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("A button")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.ButtonA] ?? "B")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("B button")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.ButtonB] ?? "A")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button{

                    } label: {
                        HStack {
                            Text("Y button")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.ButtonY] ?? "X")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("X button")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.ButtonX] ?? "Y")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("L button")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.ButtonL] ?? "L1")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("R button")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.ButtonR] ?? "R1")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("Start")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Start] ?? "Menu")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("Select")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Select] ?? "Select")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                }
                Section(header: Text("Hotkey mappings").foregroundColor(Colors.primaryColor)) {
                    Button {

                    } label: {
                        HStack {
                            Text("Control stick mode (SM64 DS only)")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Select] ?? "L2")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button() {

                    } label: {
                        HStack {
                            Text("Quick load")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Select] ?? "L3")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("Quick save")
                            Spacer()
                            Text(buttonMappings[ButtonEvent.Select] ?? "R3")
                                .foregroundColor(Colors.primaryColor)
                        }
                    }
                }

            }
            Button("Dismiss") {
                isPresented = false
            }
        }
        .font(.custom("Departure Mono", size: 18))
        .foregroundColor(themeColor)
    }
}
