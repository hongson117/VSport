//
//  HighFlySportService.swift
//  VSport (Apple TV & iOS)
//
//  Dịch vụ gọi API danh mục và luồng phát thể thao trực tiếp
//  Tự động sử dụng nguồn phát năng động từ SportConfigManager
//

import Foundation

public actor HighFlySportService {
    public static let shared = HighFlySportService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (AppleTV; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
        ]
        self.session = URLSession(configuration: config)
    }
    
    /// Lấy danh sách sự kiện thể thao theo danh mục
    public func fetchCatalog(categoryId: String) async throws -> [SportEvent] {
        let baseURL = await SportConfigManager.shared.activeBaseURL
        guard let url = URL(string: "\(baseURL)/catalog/sport/\(categoryId).json") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        let decoded = try JSONDecoder().decode(SportCatalogResponse.self, from: data)
        return decoded.metas ?? []
    }
    
    /// Lấy danh sách luồng phát trực tiếp của một sự kiện, kèm bộ lọc nghiêm ngặt
    public func fetchStreams(for eventId: String) async throws -> [SportStream] {
        let baseURL = await SportConfigManager.shared.activeBaseURL
        guard let url = URL(string: "\(baseURL)/stream/sport/\(eventId).json") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return []
        }
        
        let decoded = try JSONDecoder().decode(SportStreamResponse.self, from: data)
        guard let rawStreams = decoded.streams, !rawStreams.isEmpty else {
            return []
        }
        
        var validStreams: [SportStream] = []
        
        for raw in rawStreams {
            guard let urlString = raw.url,
                  let streamURL = URL(string: urlString) else {
                continue
            }
            
            let name = raw.name ?? ""
            let title = raw.title ?? ""
            let combined = "\(name) \(title) \(urlString)".lowercased()
            
            // 1. Bộ lọc nghiêm ngặt: Loại bỏ triệt để các luồng giả/chưa phát
            if combined.contains("google.com") ||
               combined.contains("/health") ||
               combined.contains("starts in") ||
               combined.contains("unavailable") ||
               combined.contains("match not found") ||
               combined.contains("channels may be down before the event") {
                continue
            }
            
            // 2. Nhận diện chất lượng
            let is4K = combined.contains("4k") || combined.contains("3840") || combined.contains("2160")
            let isFHD = combined.contains("fhd") || combined.contains("1080") || combined.contains("1920x1080")
            let isHD = combined.contains("720") || combined.contains("hd")
            
            let qualityTag: String
            if is4K {
                qualityTag = "4K UHD"
            } else if isFHD {
                qualityTag = "1080p FHD"
            } else if isHD {
                qualityTag = "HD 720p"
            } else {
                qualityTag = "SD"
            }
            
            // 3. Trích xuất Bitrate thực tế
            var bitrateText = is4K ? "14.8 Mbps" : "11.5 Mbps"
            if let bitMatch = title.range(of: #"\d+(\.\d+)?\s*(mbps|kbps)"#, options: .regularExpression) {
                bitrateText = String(title[bitMatch])
            }
            
            // 4. Trích xuất FPS
            var fpsText = "50 FPS"
            if let fpsMatch = title.range(of: #"\d+\s*fps"#, options: [.regularExpression, .caseInsensitive]) {
                fpsText = String(title[fpsMatch]).uppercased()
            }
            
            let stream = SportStream(
                rawName: name,
                rawTitle: title,
                url: streamURL,
                qualityTag: qualityTag,
                bitrateText: bitrateText,
                fpsText: fpsText,
                is4K: is4K
            )
            validStreams.append(stream)
        }
        
        // Sắp xếp ưu tiên: 4K UHD lên trước, rồi tới 1080p FHD, rồi tới các luồng khác
        return validStreams.sorted { s1, s2 in
            if s1.is4K != s2.is4K {
                return s1.is4K
            }
            if s1.qualityTag.contains("1080") != s2.qualityTag.contains("1080") {
                return s1.qualityTag.contains("1080")
            }
            return s1.rawName < s2.rawName
        }
    }
}
