//
//  SignalPillView.swift
//  VSport (Apple TV & iOS)
//
//  Bộ Đo Tín Hiệu Thời Gian Thực (Signal Pill Glassmorphism)
//  Hiển thị chuẩn: 📡 1080p FHD 1920×1080 • 50 FPS • 11.5 Mbps
//

import SwiftUI

public struct SignalPillView: View {
    public let signalText: String
    public let is4K: Bool
    
    public init(signalText: String, is4K: Bool = false) {
        self.signalText = signalText
        self.is4K = is4K
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(is4K ? Color.yellow : Color.green)
                .frame(width: 8, height: 8)
                .shadow(color: (is4K ? Color.yellow : Color.green).opacity(0.8), radius: 4)
            
            Text(signalText)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(
                            is4K ? Color.yellow.opacity(0.5) : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
        )
    }
}
