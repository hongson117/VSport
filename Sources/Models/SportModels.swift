//
//  SportModels.swift
//  VSport (Apple TV & iOS)
//
//  Mô hình dữ liệu sự kiện và luồng phát thể thao trực tiếp
//

import Foundation

// MARK: - 1. Danh Mục Thể Thao
public struct SportCategory: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let icon: String
    
    public init(id: String, title: String, icon: String) {
        self.id = id
        self.title = title
        self.icon = icon
    }
    
    public static let allCategories: [SportCategory] = [
        SportCategory(id: "sports_live", title: "Trực Tiếp", icon: "dot.radiowaves.left.and.right"),
        SportCategory(id: "sports_today", title: "Hôm Nay", icon: "calendar"),
        SportCategory(id: "sports_football", title: "Bóng Đá", icon: "sportscourt"),
        SportCategory(id: "sports_motor_sports", title: "Đua Xe", icon: "car.side"),
        SportCategory(id: "sports_fight", title: "Đối Kháng", icon: "figure.boxing"),
        SportCategory(id: "sports_tennis", title: "Quần Vợt", icon: "tennis.racket"),
        SportCategory(id: "sports_basketball", title: "Bóng Rổ", icon: "basketball")
    ]
}

// MARK: - 2. Phản Hồi Danh Mục Sự Kiện (Catalog JSON)
public struct SportCatalogResponse: Codable {
    public let metas: [SportEvent]?
}

// MARK: - 3. Sự Kiện Thể Thao (Sport Event Meta)
public struct SportEvent: Identifiable, Hashable, Codable {
    public let id: String
    public let type: String?
    public let name: String
    public let poster: String?
    public let posterShape: String?
    public let background: String?
    public let genres: [String]?
    public let description: String?
    public let releaseInfo: String?
    
    public var isLive: Bool {
        let rel = (releaseInfo ?? "").uppercased()
        let desc = (description ?? "").uppercased()
        let nm = name.uppercased()
        return rel.contains("LIVE") || desc.contains("LIVE") || nm.contains("LIVE")
    }
    
    public var is4K: Bool {
        let nm = name.uppercased()
        let desc = (description ?? "").uppercased()
        return nm.contains("4K") || nm.contains("2160") || desc.contains("4K") || desc.contains("2160")
    }
    
    public var isFHD: Bool {
        let nm = name.uppercased()
        let desc = (description ?? "").uppercased()
        return nm.contains("FHD") || nm.contains("1080") || desc.contains("FHD") || desc.contains("1080")
    }
    
    public var leagueOrSport: String {
        if let g = genres, !g.isEmpty {
            return g.first ?? "Thể Thao"
        }
        return "Trực Tiếp"
    }
}

// MARK: - 4. Phản Hồi Luồng Phát (Stream JSON)
public struct SportStreamResponse: Codable {
    public let streams: [SportStreamRaw]?
}

public struct SportStreamRaw: Codable {
    public let name: String?
    public let title: String?
    public let url: String?
}

// MARK: - 5. Luồng Phát Chuẩn Hóa Sau Khi Lọc (Sport Stream)
public struct SportStream: Identifiable, Hashable {
    public let id: String
    public let rawName: String
    public let rawTitle: String
    public let url: URL
    public let qualityTag: String      // "1080p FHD", "4K UHD", "HD 720p"
    public let bitrateText: String     // ví dụ "11.5 Mbps"
    public let fpsText: String         // ví dụ "50 FPS"
    public let is4K: Bool
    
    public var displayTitle: String {
        return "\(qualityTag) • \(fpsText) • \(bitrateText)"
    }
    
    public init(
        id: String = UUID().uuidString,
        rawName: String,
        rawTitle: String,
        url: URL,
        qualityTag: String,
        bitrateText: String,
        fpsText: String = "50 FPS",
        is4K: Bool
    ) {
        self.id = id
        self.rawName = rawName
        self.rawTitle = rawTitle
        self.url = url
        self.qualityTag = qualityTag
        self.bitrateText = bitrateText
        self.fpsText = fpsText
        self.is4K = is4K
    }
}
