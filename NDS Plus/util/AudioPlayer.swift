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
        buffer = Array(bufferPtr)
    }
    
    private func playAudio() {
        if let outputBuffer = AVAudioPCMBuffer(pcmFormat: self.audioFormat!, frameCapacity: AVAudioFrameCount(8192)) {
            // we just need one inputBuffer
            if let floatBuffer = outputBuffer.floatChannelData {
                var bufferPtr: UnsafePointer<Float>? = nil
                buffer.withUnsafeBufferPointer { ptr in
                    
                    bufferPtr = ptr.baseAddress!
                }
                
                // print(buffer)

                memcpy(floatBuffer[0], bufferPtr!, buffer.count * 4)
                
                let frameLength = AVAudioFrameCount((buffer.count * 4) / Int(self.audioFormat!.streamDescription.pointee.mBytesPerFrame))
                outputBuffer.frameLength = frameLength
            }
            
            self.audioNode.scheduleBuffer(outputBuffer) { [weak self, weak node = audioNode] in
                if node?.isPlaying == true {
                    if let self = self {
                        self.playAudio()
                    }
                }
            }
        }
    }
}
