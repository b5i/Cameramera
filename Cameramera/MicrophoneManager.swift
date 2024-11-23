//
//  MicrophoneController.swift
//  Cameramera
//
//  Created by Antoine Bollengier on 23.11.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import AVFoundation

class MicrophoneManager: NSObject, ObservableObject {
    static let shared = MicrophoneManager()
    
    @MainActor @Published var audioLevel: UInt8 = 0
    
    override init() {
        super.init()
        self.setUpAudioCapture()
    }
    
    // from https://betterprogramming.pub/detecting-microphone-input-levels-in-your-ios-application-e5b96bf97c5c
    private func setUpAudioCapture() {
            
        let recordingSession = AVAudioSession.sharedInstance()
            
        do {
            try recordingSession.setCategory(.playAndRecord)
            try recordingSession.setActive(true)
                
            AVAudioApplication.requestRecordPermission(completionHandler: { result in
                    guard result else { return }
            })
            self.captureAudio()

                                
        } catch {
            print("ERROR: Failed to set up recording session.")
        }
    }
    
    private func captureAudio() {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                audioRecorder.updateMeters()
                let db = audioRecorder.averagePower(forChannel: 0)
                DispatchQueue.main.async {
                    self.audioLevel = UInt8(100 - min(-db * 1.25, 100))
                }
            }
        } catch {
            print("ERROR: Failed to start recording process.")
        }
        
    }
}
