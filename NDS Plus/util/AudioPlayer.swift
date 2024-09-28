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
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.allowAirPlay, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
        self.startAudio()
    }
    
    func startAudio() {
        self.audioNode.reset()
        
        self.audioEngine.disconnectNodeOutput(self.audioNode)
        self.audioEngine.connect(self.audioNode, to: self.audioEngine.mainMixerNode, format: self.audioFormat)
        
        
    }
}
