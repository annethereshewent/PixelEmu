//
//  AudioManager.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/26/24.
//

import Foundation
import AVFoundation

class AudioManager {
    private let audioEngine = AVAudioEngine()
    private let audioNode = AVAudioPlayerNode()
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
    private var mic: AVAudioInputNode?

    private let nslock = NSLock()

    private var buffer: [Float] = []

    private var sampleIndex = 0

    private var micBuffer: [Float] = []
    private var samples: [Float] = [Float](repeating: 0.0, count: 4800)

    private var sourceBuffer: AVAudioPCMBuffer!

    private var converter: AVAudioConverter!

    var playerPaused: Bool = false

    var bufferPtr: UnsafeBufferPointer<Float>? = nil

    var isRunning = true

    func startAudio() {
        do {
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowAirPlay, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)

            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)

            self.audioEngine.attach(self.audioNode)
            self.audioEngine.connect(self.audioNode, to: self.audioEngine.outputNode, format: self.audioFormat)

            try self.audioEngine.start()

            self.audioNode.play()

            DispatchQueue.global().async {
                self.playAudio()
            }
        } catch {
            print(error)
        }
    }

    func startMicrophoneAndAudio() {
        do {
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowAirPlay, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)

            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)


            self.audioEngine.attach(self.audioNode)
            self.audioEngine.connect(self.audioNode, to: self.audioEngine.outputNode, format: self.audioFormat)

            mic = audioEngine.inputNode

            let micFormat = mic!.inputFormat(forBus: 0)

            sourceBuffer = AVAudioPCMBuffer(pcmFormat: micFormat, frameCapacity: 4096)

            if let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 1, interleaved: false) {
                converter = AVAudioConverter(from: micFormat, to: outputFormat)
            }

            mic!.installTap(onBus: 0, bufferSize: 2048, format: micFormat) { (buffer, when) in
                if !self.isRunning {
                    self.mic!.removeTap(onBus: 0)
                }
                if let outputBuffer = AVAudioPCMBuffer(pcmFormat: self.converter.outputFormat, frameCapacity: buffer.frameCapacity) {
                    var error: NSError?

                    _ = self.converter.convert(to: outputBuffer, error: &error) { [unowned self] numberOfFrames, inputStatus in
                        inputStatus.pointee = .haveData
                        return buffer
                    }
                    let samples = Array(UnsafeBufferPointer(start: outputBuffer.floatChannelData![0], count: Int(outputBuffer.frameLength)))

                    self.nslock.lock()
                    self.micBuffer.append(contentsOf: samples)
                    self.nslock.unlock()
                }
            }

            try self.audioEngine.start()

            self.audioNode.play()

            DispatchQueue.global().async {
                self.playAudio()
            }
        } catch {
            print(error)
        }
    }

    func stopMicrophone() {
        mic?.removeTap(onBus: 0)
    }

    func getBufferPtr() -> UnsafeBufferPointer<Float>? {
        if sampleIndex + micBuffer.count > samples.count {
            sampleIndex = 0
        }

        nslock.lock()
        while micBuffer.count > 0 && sampleIndex < samples.count {
            samples[sampleIndex] = micBuffer.removeFirst()
            sampleIndex += 1
        }
        nslock.unlock()

        var bufferPtr: UnsafeBufferPointer<Float>!

        samples.withUnsafeBufferPointer() { ptr in
            bufferPtr = ptr
        }

        return bufferPtr
    }

    func updateBuffer(samples: [Float]) {
        if audioNode.isPlaying {
            nslock.lock()
            buffer.append(contentsOf: samples)
            nslock.unlock()
        }
    }

    func popSamples(emu: EmulatorWrapper) {
        nslock.lock()
        while emu.hasSamples() {
            try! buffer.append(emu.popSample())
        }
        nslock.unlock()
    }

    func toggleAudio() {
        if audioNode.isPlaying {
            playerPaused = true
            audioNode.pause()
        } else {
            playerPaused = false
            audioNode.play()
        }
    }

    func muteAudio() {
        if audioNode.isPlaying && !playerPaused {
            audioNode.pause()
        }
    }

    func resumeAudio() {
        if !audioNode.isPlaying && !playerPaused {
            audioNode.play()
        }
    }

    private func playAudio() {
        if let outputBuffer = AVAudioPCMBuffer(pcmFormat: self.audioFormat!, frameCapacity: AVAudioFrameCount(8192 * 2)) {
            // we just need one inputBuffer
            if let floatBuffer = outputBuffer.floatChannelData {
                var isEven = true

                var leftIndex = 0
                var rightIndex = 0

                nslock.lock()
                while buffer.count > 0 {
                    let sample = buffer.removeFirst()
                    if isEven {
                        floatBuffer[0][leftIndex] = sample
                        leftIndex += 1
                    } else {
                        floatBuffer[1][rightIndex] = sample
                        rightIndex += 1
                    }
                    isEven = !isEven
                }
                nslock.unlock()

                let frameLength = AVAudioFrameCount(8192)
                outputBuffer.frameLength = frameLength
            }

            self.audioNode.scheduleBuffer(outputBuffer) { [weak self, weak node = self.audioNode] in
                if node?.isPlaying == true {
                    if let self = self {
                        DispatchQueue.global().async {
                            self.playAudio()
                        }
                    }
                }
            }
        }
    }
}
