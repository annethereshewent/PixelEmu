//
//  EmulatorWrapper.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/17/25.
//

import Foundation
import GBAEmulatorMobile
import DSEmulatorMobile
import GBCEmulatorMobile

protocol EmulatorWrapper {
    func setPaused(_ paused: Bool)
    func stepFrame()
    func createSaveState() -> UnsafePointer<UInt8>?
    func compressedLength() -> UInt
    func hasSaved() -> Bool
    func setSaved(_ value: Bool) throws
    func setBackup(_ save_type: String, _ ram_capacity: UInt, _ bytes: UnsafeBufferPointer<UInt8>) throws
    func backupPointer() -> UnsafePointer<UInt8>
    func backupLength() -> UInt
    func updateInput(_ button: PressedButton, _ value: Bool)
    func updateAudioBuffer(_ ptr: UnsafeBufferPointer<Float>) throws
    func getGameCode() throws -> UInt32
    func load(_ ptr: UnsafeBufferPointer<UInt8>) throws
    func loadBios(_ ptr: UnsafeBufferPointer<UInt8>) throws
    func getEngineAPicturePointer() throws -> UnsafePointer<UInt8>
    func getEngineBPicturePointer() throws -> UnsafePointer<UInt8>
    func isTopA() -> Bool
    func getPicturePtr() throws -> UnsafePointer<UInt8>
    func audioBufferLength() throws -> UInt
    func audioBufferPtr() throws -> UnsafePointer<Float>
    func touchScreen(_ x: UInt16, _ y: UInt16) throws
    func pressScreen() throws
    func releaseScreen() throws
    func touchScreenController(_ x: Float, _ y: Float) throws
    func loadSaveState(_ ptr: UnsafeBufferPointer<UInt8>)
    func reloadRom(_ ptr: UnsafeBufferPointer<UInt8>)
    func reloadFirmware(_ ptr: UnsafeBufferPointer<UInt8>) throws
    func hleFirmware() throws
    func reloadBios(_ bios7: UnsafeBufferPointer<UInt8>, _ bios9: UnsafeBufferPointer<UInt8>) throws
    func loadIcon() throws
    func getGameIconPointer() throws -> UnsafePointer<UInt8>
    func loadSave(_ ptr: UnsafeBufferPointer<UInt8>) throws
    func hasSamples() -> Bool
    func popSample() throws -> Float
    func setPausedAudio(_ value: Bool)
}

class DSEmulatorWrapper: EmulatorWrapper {
    var emu: MobileEmulator

    init (emu: MobileEmulator) {
        self.emu = emu
    }

    func hasSamples() -> Bool {
        false
    }

    func popSample() throws -> Float {
        throw "not implemented"
    }

    func loadIcon() throws {
        emu.loadIcon()
    }

    func getGameIconPointer() throws -> UnsafePointer<UInt8> {
        return emu.getGameIconPointer()
    }

    func touchScreen(_ x: UInt16, _ y: UInt16) throws {
        emu.touchScreen(x, y)
    }

    func pressScreen() throws {
        emu.pressScreen()
    }

    func releaseScreen() throws {
        emu.releaseScreen()
    }

    func createSaveState() -> UnsafePointer<UInt8>? {
        return emu.createSaveState()
    }

    func backupPointer() -> UnsafePointer<UInt8> {
        return emu.backupPointer()
    }

    func backupLength() -> UInt {
        return emu.backupLength()
    }

    func setPaused(_ paused: Bool) {
        emu.setPause(paused)
    }

    func stepFrame() {
        emu.stepFrame()
    }

    func compressedLength() -> UInt {
        return emu.compressedLength()
    }

    func hasSaved() -> Bool {
        emu.hasSaved()
    }

    func setSaved(_ value: Bool) throws {
        emu.setSaved(value)
    }

    func setBackup(_ save_type: String, _ ram_capacity: UInt, _ bytes: UnsafeBufferPointer<UInt8>) {
        emu.setBackup(save_type, ram_capacity, bytes)
    }

    func updateInput(_ button: PressedButton, _ value: Bool) {
        emu.updateInput(UInt(button.rawValue), value)
    }

    func updateAudioBuffer(_ ptr: UnsafeBufferPointer<Float>) {
        emu.updateAudioBuffer(ptr)
    }

    func getGameCode() throws -> UInt32 {
        return emu.getGameCode()
    }

    func load(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }

    func loadBios(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }
    func getEngineAPicturePointer() throws -> UnsafePointer<UInt8> {
        return emu.getEngineAPicturePointer()
    }
    func getEngineBPicturePointer() throws -> UnsafePointer<UInt8> {
        return emu.getEngineBPicturePointer()
    }
    func isTopA() -> Bool {
        return emu.isTopA()
    }

    func getPicturePtr() throws -> UnsafePointer<UInt8> {
        throw "not implemented"
    }
    func audioBufferLength() -> UInt {
        return emu.audioBufferLength()
    }
    func audioBufferPtr() -> UnsafePointer<Float> {
        return emu.audioBufferPtr()
    }

    func touchScreenController(_ x: Float, _ y: Float) throws {
        emu.touchScreenController(x, y)
    }

    func loadSaveState(_ ptr: UnsafeBufferPointer<UInt8>) {
        emu.loadSaveState(ptr)
    }

    func reloadRom(_ ptr: UnsafeBufferPointer<UInt8>) {
        emu.reloadRom(ptr)
    }

    func reloadFirmware(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        emu.reloadFirmware(ptr)
    }

    func hleFirmware() {
        emu.hleFirmware()
    }

    func reloadBios(_ bios7: UnsafeBufferPointer<UInt8>, _ bios9: UnsafeBufferPointer<UInt8>) throws {
        emu.reloadBios(bios7, bios9)
    }

    func loadSave(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }

    func setPausedAudio(_ value: Bool) {
        emu.setPausedAudio(value)
    }
}

class GBAEmulatorWrapper: EmulatorWrapper {
    var emu: GBAEmulator

    init (emu: GBAEmulator) {
        self.emu = emu
    }

    func hasSamples() -> Bool {
        false
    }

    func popSample() throws -> Float {
        throw "not implemented"
    }

    func loadIcon() throws {
        throw "not implemented"
    }

    func getGameIconPointer() throws -> UnsafePointer<UInt8> {
        throw "not implemented"
    }

    func isTopA() -> Bool {
        return false
    }

    func getPicturePtr() throws -> UnsafePointer<UInt8> {
        return emu.getPicturePtr()
    }

    func createSaveState() -> UnsafePointer<UInt8>? {
        return emu.createSaveState()
    }

    func backupPointer() -> UnsafePointer<UInt8> {
        return emu.backupFilePointer()
    }

    func backupLength() -> UInt {
        return emu.backupFileSize()
    }

    func setPaused(_ paused: Bool) {
        emu.setPaused(paused)
    }

    func stepFrame() {
        emu.stepFrame()
    }

    func compressedLength() -> UInt {
        return emu.compressedLength()
    }

    func hasSaved() -> Bool {
        emu.hasSaved()
    }

    func setSaved(_ value: Bool) throws {
        emu.setSaved(value)
    }

    func setBackup(_ save_type: String, _ ram_capacity: UInt, _ bytes: UnsafeBufferPointer<UInt8>) throws {
        // do nothing
        throw "not implemented"
    }

    func updateInput(_ button: PressedButton, _ value: Bool) {
        emu.updateInput(UInt(button.rawValue), value)
    }

    func updateAudioBuffer(_ ptr: UnsafeBufferPointer<Float>) throws {
        throw "not implemented"
    }

    func getGameCode() throws -> UInt32 {
        throw "not implemented"
    }

    func load(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        emu.load(ptr)
    }

    func loadBios(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        emu.loadBios(ptr)
    }
    func getEngineAPicturePointer() throws -> UnsafePointer<UInt8> {
        throw "Not implemented"
    }
    func getEngineBPicturePointer() throws -> UnsafePointer<UInt8> {
        throw "Not implemented"
    }
    func audioBufferLength() -> UInt {
        return emu.audioBufferLength()
    }
    func audioBufferPtr() -> UnsafePointer<Float> {
        return emu.audioBufferPtr()
    }

    func touchScreen(_ x: UInt16, _ y: UInt16) throws {
        throw "not implemented"
    }

    func pressScreen() throws {
        throw "not implemented"
    }

    func releaseScreen() throws {
        throw "not implemented"
    }
    func touchScreenController(_ x: Float, _ y: Float) throws {
        throw "not implemented"
    }

    func loadSaveState(_ ptr: UnsafeBufferPointer<UInt8>) {
        emu.loadSaveState(ptr)
    }

    func reloadRom(_ ptr: UnsafeBufferPointer<UInt8>) {
        emu.reloadRom(ptr)
    }

    func reloadFirmware(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }

    func hleFirmware() throws {
        throw "not implemented"
    }
    func reloadBios(_ bios7: UnsafeBufferPointer<UInt8>, _ bios9: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }

    func loadSave(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        emu.loadSave(ptr)
    }

    func setPausedAudio(_ value: Bool) {
        emu.setPausedAudio(value)
    }
}

class GBCEmulatorWrapper : EmulatorWrapper {
    var emu: GBCMobileEmulator

    init (emu: GBCMobileEmulator) {
        self.emu = emu
    }

    func hasSamples() -> Bool {
       return self.emu.hasSamples()
    }

    func popSample() throws -> Float {
        return self.emu.popSample()
    }

    func loadIcon() throws {
        throw "not implemented"
    }

    func getGameIconPointer() throws -> UnsafePointer<UInt8> {
        throw "not implemented"
    }

    func isTopA() -> Bool {
        return false
    }

    func getPicturePtr() throws -> UnsafePointer<UInt8> {
        return emu.getScreen()
    }

    func createSaveState() -> UnsafePointer<UInt8>? {
        return emu.createSaveState()
    }

    func backupPointer() -> UnsafePointer<UInt8> {
        return emu.saveGame()
    }

    func backupLength() -> UInt {
        return emu.getSaveLength()
    }

    func setPaused(_ paused: Bool) {
        emu.setPaused(paused)
    }

    func stepFrame() {
        emu.stepFrame()
    }

    func compressedLength() -> UInt {
        return emu.saveStateLength()
    }

    func hasSaved() -> Bool {
        emu.hasSaved()
    }

    func setSaved(_ value: Bool) throws {
        throw "not implemented"
    }

    func setBackup(_ save_type: String, _ ram_capacity: UInt, _ bytes: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }

    func updateInput(_ button: PressedButton, _ value: Bool) {
        emu.updateInput(UInt(button.rawValue), value)
    }

    func updateAudioBuffer(_ ptr: UnsafeBufferPointer<Float>) throws {
        throw "not implemented"
    }

    func getGameCode() throws -> UInt32 {
        throw "not implemented"
    }

    func load(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        emu.loadRom(ptr)
    }

    func loadBios(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }
    func getEngineAPicturePointer() throws -> UnsafePointer<UInt8> {
        throw "not implemented"
    }
    func getEngineBPicturePointer() throws -> UnsafePointer<UInt8> {
        throw "not implemented"
    }
    func audioBufferLength() -> UInt {
        return emu.getBufferLength()
    }
    func audioBufferPtr() -> UnsafePointer<Float> {
        return emu.readRingBuffer()
    }

    func touchScreen(_ x: UInt16, _ y: UInt16) throws {
        throw "not implemented"
    }

    func pressScreen() throws {
        throw "not implemented"
    }

    func releaseScreen() throws {
        throw "not implemented"
    }
    func touchScreenController(_ x: Float, _ y: Float) throws {
        throw "not implemented"
    }

    func loadSaveState(_ ptr: UnsafeBufferPointer<UInt8>) {
        emu.loadSaveState(ptr)
    }

    func reloadRom(_ ptr: UnsafeBufferPointer<UInt8>) {
        emu.reloadRom(ptr)
    }

    func reloadFirmware(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }

    func hleFirmware() throws {
        throw "not implemented"
    }
    func reloadBios(_ bios7: UnsafeBufferPointer<UInt8>, _ bios9: UnsafeBufferPointer<UInt8>) throws {
        throw "not implemented"
    }

    func loadSave(_ ptr: UnsafeBufferPointer<UInt8>) throws {
        emu.loadSave(ptr)
    }

    func setPausedAudio(_ value: Bool) {
        emu.setPausedAudio(value)
    }
}
