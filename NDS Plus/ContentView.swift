//
//  ContentView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI
import UniformTypeIdentifiers
import DSEmulatorMobile

struct ContentView: View {
    @State private var showSettings = false
    @State private var showRomDialog = false

    @State private var bios7Data: Data? = nil
    @State private var bios9Data: Data? = nil
    @State private var firmwareData: Data? = nil
    @State private var romData: Data? = nil
    @State private var topImage: UIImage = UIImage()
    @State private var bottomImage: UIImage = UIImage()
    
    @State private var workItem: DispatchWorkItem? = nil
    @State private var isRunning = false
    
    let graphicsParser = GraphicsParser()
    
    @State private var emulator: MobileEmulator? = nil
    
    let ndsType = UTType(filenameExtension: "nds", conformingTo: .data)
    
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
            // Spacer()
            Image(uiImage: topImage)
                .frame(width: 256, height: 192)
            Image(uiImage: bottomImage)
                .frame(width: 256, height: 192)
                .onTapGesture() { location in
                    emulator?.touch_screen(UInt16(location.x), UInt16(location.y))
                    DispatchQueue.global().async(execute: DispatchWorkItem {
                        usleep(200)
                        DispatchQueue.main.sync() {
                            emulator?.release_screen()
                        }
                    })
                }
                
            Spacer()
            HStack {
                Button("Load Game", systemImage: "square.and.arrow.up.circle") {
                    emulator = nil
                    workItem?.cancel()
                    isRunning = false
                    
                    workItem = nil
                    
                    showRomDialog = true
                }
                .foregroundColor(buttonColor)
                .disabled(buttonDisabled)
                .font(.title)
            }
            Spacer()
        }
        .fileImporter(
            isPresented: $showRomDialog,
            allowedContentTypes: [ndsType.unsafelyUnwrapped]
        ) { result in
            if let url = try? result.get() {
                if url.startAccessingSecurityScopedResource() {
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    if let data = try? Data(contentsOf: url) {

                        romData = data
                        
                        if bios7Data != nil && bios9Data != nil && firmwareData != nil {
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
                            
                            // we finally have an emulator!
                            emulator = DSEmulatorMobile.MobileEmulator(
                                bios7Ptr!,
                                bios9Ptr!,
                                firmwarePtr!,
                                romPtr!
                            )
                            
                            isRunning = true
                            
                            workItem = DispatchWorkItem {
                                if let emu = emulator {
                                    while true {
                                        DispatchQueue.main.sync {
                                            emu.step_frame()
                                            
                                            let aPixels = emu.get_engine_a_picture_pointer()
                                            
                                            var imageA = UIImage()
                                            var imageB = UIImage()
                                            
                                            if let image = graphicsParser.fromPointer(ptr: aPixels) {
                                                imageA = image
                                            }
                                            
                                            let bPixels = emu.get_engine_b_picture_pointer()
                                            
                                            if let image = graphicsParser.fromPointer(ptr: bPixels) {
                                                imageB = image
                                                
                                            }
                                            
                                            if emu.is_top_a() {
                                                topImage = imageA
                                                bottomImage = imageB
                                            } else {
                                                topImage = imageB
                                                bottomImage = imageA
                                            }
                                        }
                                        
                                        if !isRunning {
                                            break
                                        }
                                    }
                                }
                                
                            }
                            
                            DispatchQueue.global().async(execute: workItem!)
                        }
                    }
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
        .fileImporter(
            isPresented: $showFileBrowser,
            allowedContentTypes: [binType.unsafelyUnwrapped]
        ) { result in
            if let url = try? result.get() {
                if url.startAccessingSecurityScopedResource() {
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
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
            
            if bios7Data != nil && bios9Data != nil && firmwareData != nil {
                dismiss()
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
