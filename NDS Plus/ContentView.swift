//
//  ContentView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI

struct ContentView: View {
    @State private var showSettings = false
    @State private var bios7Loaded = false
    @State private var bios9Loaded = false
    @State private var firmwareLoaded = false
    
    var buttonDisabled: Bool {
        return !bios7Loaded || !bios9Loaded || !firmwareLoaded
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
    
    
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("", systemImage: "gear") {
                    showSettings.toggle()
                }
                .frame(alignment: .trailing)
                .foregroundColor(.indigo)
                .padding(.trailing)

            }
            .sheet(isPresented: $showSettings) {
                VStack {
                    SettingsView(
                        bios7Loaded: $bios7Loaded,
                        bios9Loaded: $bios9Loaded,
                        firmwareLoaded: $firmwareLoaded
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
            Spacer()
            HStack {
                Button("Load Game", systemImage: "square.and.arrow.up.circle") {
                    print("you clicked me!")
                }
                .foregroundColor(buttonColor)
                .disabled(buttonDisabled)
                .font(.title)
            }
            Spacer()
        }
        .background(colorScheme == .dark ? Color.black : Color.white )
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var bios7Loaded: Bool
    @Binding var bios9Loaded: Bool
    @Binding var firmwareLoaded: Bool
    
    @State private var showFileBrowser = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.title)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            List {
                HStack {
                    Button("Bios 7") {
                       
                    }
                    Spacer()
                    if bios7Loaded {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    Button("Bios 9") {
                        bios9Loaded = true
                    }
                    Spacer()
                    if bios9Loaded {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
               
                HStack {
                    Button("Firmware") {
                        firmwareLoaded = true
                    }
                    Spacer()
                    if firmwareLoaded {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
            }
            Spacer()
            Button("Dismiss") {
                dismiss()
            }
        }
        .sheet(isPresented: $showFileBrowser) {
            
        }
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
