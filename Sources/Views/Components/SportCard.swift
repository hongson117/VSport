//
//  SportCard.swift
//  VSport (Apple TV & iOS)
//
//  Thẻ sự kiện thể thao 16:9 kèm huy hiệu [LIVE] đỏ và [4K UHD] vàng kim
//

import SwiftUI

public struct SportCard: View {
    public let event: SportEvent
    public let action: () -> Void
    
    #if os(tvOS)
    @FocusState private var isFocused: Bool
    #endif
    
    public init(event: SportEvent, action: @escaping () -> Void) {
        self.event = event
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Khung Poster Tỷ Lệ 16:9
                ZStack(alignment: .topLeading) {
                    if let posterStr = event.poster, let posterURL = URL(string: posterStr) {
                        AsyncImage(url: posterURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(16/9, contentMode: .fill)
                            case .failure(_), .empty:
                                placeholderPoster
                            @unknown default:
                                placeholderPoster
                            }
                        }
                    } else {
                        placeholderPoster
                    }
                    
                    // Lớp phủ Gradient tạo chiều sâu
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.8)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    
                    // Cụm Huy Hiệu (Badges)
                    HStack(spacing: 6) {
                        if event.isLive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .shadow(color: .red.opacity(0.6), radius: 4)
                        }
                        
                        if event.is4K {
                            Text("4K UHD")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .shadow(color: .yellow.opacity(0.5), radius: 3)
                        } else if event.isFHD {
                            Text("1080p FHD")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                    
                    // Giải đấu / Môn thi đấu ở góc dưới poster
                    VStack {
                        Spacer()
                        HStack {
                            Text(event.leagueOrSport)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                .aspectRatio(16/9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                
                // Tên trận đấu & Thời gian
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let rel = event.releaseInfo, !rel.isEmpty {
                        Text(rel)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .buttonStyle(.plain)
        #if os(tvOS)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isFocused)
        #endif
    }
    
    private var placeholderPoster: some View {
        ZStack {
            Color.black.opacity(0.6)
            VStack(spacing: 8) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.3))
                Text("VSPORT")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
}
