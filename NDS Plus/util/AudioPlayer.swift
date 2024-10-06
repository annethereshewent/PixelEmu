//
//  AudioPlayer.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/26/24.
//

import Foundation
import AVFoundation

class AudioPlayer {
    private let audioEngine = AVAudioEngine()
    private let audioNode = AVAudioPlayerNode()
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
    private var mic: AVAudioInputNode!
    
    private let nslock = NSLock()
    
    private var buffer: [Float] = []
    
    private var sampleIndex = 0
    
    private var micBuffer: [Float] = []
    private var samples: [Float] = [Float](repeating: 0.0, count: 2048)
    
    var isRunning = true
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowAirPlay, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().setAllowHapticsAndSystemSoundsDuringRecording(true)
            
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            
            self.audioEngine.attach(self.audioNode)
            self.audioEngine.connect(self.audioNode, to: self.audioEngine.outputNode, format: self.audioFormat)
            
            mic = audioEngine.inputNode
            let micFormat = mic.inputFormat(forBus: 0)

            mic.installTap(onBus: 0, bufferSize: 1024, format: micFormat) { (buffer, when) in
                let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
                self.micBuffer.append(contentsOf: samples)
                
                if !self.isRunning {
                    self.mic.removeTap(onBus: 0)
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
    
    func getSamples() -> [Float]? {
        while micBuffer.count > 0 && sampleIndex < 2048 {
            samples[sampleIndex] = micBuffer.remove(at: 0)
            sampleIndex += 1
        }
        
        if sampleIndex == 2048 {
            sampleIndex = 0
            return samples
        }
        
        return nil
    }
    
    func updateBuffer(bufferPtr: UnsafeBufferPointer<Float>) {
        let samples = Array(bufferPtr)

        nslock.lock()
        buffer.append(contentsOf: samples)
        nslock.unlock()
    }
    
    private func playAudio() {
        if let outputBuffer = AVAudioPCMBuffer(pcmFormat: self.audioFormat!, frameCapacity: AVAudioFrameCount(8192*2)) {
            // we just need one inputBuffer
            if let floatBuffer = outputBuffer.floatChannelData {
                var left = [Float]()
                var right = [Float]()
                
                var isEven = true
                
                var numSamples = 0
                
                nslock.lock()
                while buffer.count > 0 {
                    let sample = buffer.removeFirst()
                    if isEven {
                        left.append(sample)
                    } else {
                        right.append(sample)
                    }
                    numSamples += 1
                    isEven = !isEven
                }
                nslock.unlock()
                
                var leftPtr: UnsafePointer<Float>? = nil
                
                left.withUnsafeBufferPointer { ptr in
                    leftPtr = ptr.baseAddress
                }
                
                var rightPtr: UnsafePointer<Float>? = nil
                
                right.withUnsafeBufferPointer { ptr in
                    rightPtr = ptr.baseAddress
                }

                memcpy(floatBuffer[0], leftPtr!, left.count * 4)
                memcpy(floatBuffer[1], rightPtr!, right.count * 4)
                
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
