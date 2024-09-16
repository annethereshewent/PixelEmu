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
    
    
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
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
            SettingsView(
                bios7Loaded: $bios7Loaded,
                bios9Loaded: $bios9Loaded,
                firmwareLoaded: $firmwareLoaded
            )
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
            .disabled(!bios7Loaded || !bios9Loaded || !firmwareLoaded)
            .font(.title)
        }
        Spacer()
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var bios7Loaded: Bool
    @Binding var bios9Loaded: Bool
    @Binding var firmwareLoaded: Bool
    
    var body: some View {
        HStack {
            Text("Settings")
                .font(.title)
        }
        List {
            HStack {
                Button("Bios 7") {
                    bios7Loaded = true
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
}

#Preview {
    ContentView()
}
