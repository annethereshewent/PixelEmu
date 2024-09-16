//
//  ContentView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showSettings = false
    @State private var showRomDialog = false

    @State private var bios7Data: Data? = nil
    @State private var bios9Data: Data? = nil
    @State private var firmwareData: Data? = nil
    @State private var romData: Data? = nil
    
    let ndsType = UTType("com.nds.nds")
    
    var buttonDisabled: Bool {
        return bios7Data == nil || bios9Data == nil || firmwareData == nil
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
                        bios7Data: $bios7Data,
                        bios9Data: $bios9Data,
                        firmwareData: $firmwareData
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
                    showRomDialog = true
                }
                .foregroundColor(buttonColor)
                .disabled(buttonDisabled)
                .font(.title)
            }
            Spacer()
        }
        .fileImporter(isPresented: $showRomDialog, allowedContentTypes: [ndsType.unsafelyUnwrapped]) { result in
        
            if let url = try? result.get() {
                if let data = try? Data(contentsOf: url) {
                    romData = data
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white )
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    
    @State private var showFileBrowser = false
    
    @State private var currentFile: CurrentFile? = nil
    
    let binType = UTType(filenameExtension: "bin", conformingTo: .data)

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
                        showFileBrowser = true
                        currentFile = CurrentFile.bios7
                    }
                    Spacer()
                    if bios7Data != nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
                
                HStack {
                    Button("Bios 9") {
                        showFileBrowser = true
                        currentFile = CurrentFile.bios9
                    }
                    Spacer()
                    if bios9Data != nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
               
                HStack {
                    Button("Firmware") {
                        showFileBrowser = true
                        currentFile = CurrentFile.firmware
                    }
                    Spacer()
                    if firmwareData != nil {
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
        .fileImporter(isPresented: $showFileBrowser, allowedContentTypes: [binType.unsafelyUnwrapped]) { result in
            
            
            if let url = try? result.get() {
                if let data = try? Data(contentsOf: url) {
                    
                    if let file = currentFile {
                        switch file {
                        case .bios7:
                            bios7Data = data
                        case .bios9:
                            bios9Data = data
                        case .firmware:
                            firmwareData = data
                        }
                    }
                }
                
            }
            
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
