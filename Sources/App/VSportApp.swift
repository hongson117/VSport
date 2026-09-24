//
//  VSportApp.swift
//  VSport (Apple TV & iOS)
//
//  Điểm khởi nhập chính của ứng dụng VSport
//

import SwiftUI
import AVFoundation

@main
struct VSportApp: App {
    init() {
        // Thiết lập cấu hình Audio Session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Lỗi thiết lập AVAudioSession: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
