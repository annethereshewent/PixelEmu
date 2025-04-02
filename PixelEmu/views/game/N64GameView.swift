//
//  N64GameView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/1/25.
//

import SwiftUI

let SRAM_SIZE = 0x8000
let FLASH_SIZE = 0x20000
let EEPROM_SIZE = 0x800
let MEMPAK_SIZE = 0x8000

let SRAM_TYPE: Int32 = 0
let FLASH_TYPE: Int32 = 1
let EEPROM4K_TYPE: Int32 = 2
let EEPROM16K_TYPE: Int32 = 3
let MEMPAK_TYPE: Int32 = 4

struct N64GameView: View {
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    @State private var backupFiles: [BackupFile] = []

    var body: some View {
        if gameUrl != nil {
            HStack {
                SDLView(romData: $romData)
                    .edgesIgnoringSafeArea(.all)
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
            .edgesIgnoringSafeArea(.all)
            .statusBarHidden()
            .onAppear {
                backupFiles = []
                let ptr = getSaveTypes()
                let count = getSaveTypesSize()

                let buffer = UnsafeBufferPointer(start: ptr, count: Int(count))

                let saveTypes = Array(buffer)

                for type in saveTypes {
                    switch (type) {
                    case SRAM_TYPE:
                        backupFiles.append(BackupFile(capacity: SRAM_SIZE, gameUrl: gameUrl!))
                    case FLASH_TYPE:
                        backupFiles.append(BackupFile(capacity: FLASH_SIZE, gameUrl: gameUrl!))
                    case EEPROM4K_TYPE:
                        backupFiles.append(BackupFile(capacity: EEPROM_SIZE, gameUrl: gameUrl!))
                    case EEPROM16K_TYPE:
                        backupFiles.append(BackupFile(capacity: EEPROM_SIZE, gameUrl: gameUrl!))
                    case MEMPAK_TYPE:
                        backupFiles.append(BackupFile(capacity: MEMPAK_SIZE, gameUrl: gameUrl!))
                    default:
                        print("invalid backup file specified")
                    }
                }
            }
        }
    }

}
