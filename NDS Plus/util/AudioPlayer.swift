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
    
    private let nslock = NSLock()
    
    private var buffer: [Float] = []
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowAirPlay, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            
            self.audioEngine.attach(self.audioNode)
            self.audioEngine.connect(self.audioNode, to: self.audioEngine.outputNode, format: self.audioFormat)
            
            try self.audioEngine.start()
            
            self.audioNode.play()
            
            self.playAudio()
        } catch {
            print(error)
        }
    }
    
    func updateBuffer(bufferPtr: UnsafeBufferPointer<Float>) {
        let samples = Array(bufferPtr)

        nslock.lock()
        buffer.append(contentsOf: samples)
        nslock.unlock()
    }
    
    private func playAudio() {
        if let outputBuffer = AVAudioPCMBuffer(pcmFormat: self.audioFormat!, frameCapacity: AVAudioFrameCount(8192)) {
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
                
                let frameLength = AVAudioFrameCount(4096)
                outputBuffer.frameLength = frameLength
            }
                        
            self.audioNode.scheduleBuffer(outputBuffer) { [weak self, weak node = self.audioNode] in
                if node?.isPlaying == true {
                    if let self = self {
                        self.playAudio()
                    }
                }
            }
        }
    }
}
