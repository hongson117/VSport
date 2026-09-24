//
//  SportConfigManager.swift
//  VSport (Apple TV & iOS)
//
//  Quản lý cấu hình nguồn phát thể thao (BYOK - Bring Your Own Key):
//  - Mặc định: Nguồn miễn phí https://sports.highfly.to/manifest.json (Đầy đủ đến 1080p FHD).
//  - Cho phép người dùng tự điền link Premium cá nhân dạng JSON/Manifest khi mua.
//  - Tự động đồng bộ iCloud giữa iPhone & Apple TV.
//

import Foundation
import Combine

public class SportConfigManager: ObservableObject {
    public static let shared = SportConfigManager()
    
    public static let defaultManifestURL = "https://sports.highfly.to/manifest.json"
    private let storageKey = "custom_sport_manifest_url"
    
    @Published public var currentManifestURL: String {
        didSet {
            UserDefaults.standard.set(currentManifestURL, forKey: storageKey)
            NSUbiquitousKeyValueStore.default.set(currentManifestURL, forKey: storageKey)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    private init() {
        // Đọc từ iCloud trước, nếu không có đọc UserDefaults, cuối cùng dùng mặc định
        NSUbiquitousKeyValueStore.default.synchronize()
        if let cloudURL = NSUbiquitousKeyValueStore.default.string(forKey: storageKey), !cloudURL.isEmpty {
            self.currentManifestURL = cloudURL
        } else if let localURL = UserDefaults.standard.string(forKey: storageKey), !localURL.isEmpty {
            self.currentManifestURL = localURL
        } else {
            self.currentManifestURL = SportConfigManager.defaultManifestURL
        }
        
        // Lắng nghe thay đổi từ iCloud (khi nhập trên iPhone, Apple TV tự cập nhật)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
    }
    
    @objc private func iCloudStoreDidChange(notification: Notification) {
        if let cloudURL = NSUbiquitousKeyValueStore.default.string(forKey: storageKey), !cloudURL.isEmpty {
            DispatchQueue.main.async {
                if self.currentManifestURL != cloudURL {
                    self.currentManifestURL = cloudURL
                }
            }
        }
    }
    
    /// Trả về URL gốc (Base URL) sạch sẽ, đã loại bỏ đuôi /manifest.json và dấu gạch chéo cuối
    public var activeBaseURL: String {
        var url = currentManifestURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if url.hasSuffix("/manifest.json") {
            url = String(url.dropLast("/manifest.json".count))
        }
        if url.hasSuffix("/") {
            url = String(url.dropLast(1))
        }
        return url
    }
    
    public var isUsingDefault: Bool {
        return activeBaseURL == "https://sports.highfly.to"
    }
    
    /// Lưu URL tuỳ chỉnh do người dùng nhập
    public func saveCustomURL(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            resetToDefault()
        } else {
            currentManifestURL = trimmed
        }
    }
    
    /// Khôi phục nguồn mặc định miễn phí
    public func resetToDefault() {
        currentManifestURL = SportConfigManager.defaultManifestURL
    }
    
    /// Kiểm tra tính hợp lệ của nguồn phát
    public func testConnection(urlString: String) async -> (success: Bool, message: String) {
        var base = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty {
            base = SportConfigManager.defaultManifestURL
        }
        if base.hasSuffix("/manifest.json") {
            base = String(base.dropLast("/manifest.json".count))
        }
        if base.hasSuffix("/") {
            base = String(base.dropLast(1))
        }
        
        guard let testURL = URL(string: "\(base)/catalog/sport/sports_live.json") else {
            return (false, "Địa chỉ URL không hợp lệ!")
        }
        
        do {
            var request = URLRequest(url: testURL, timeoutInterval: 8.0)
            request.setValue("Mozilla/5.0 (AppleTV; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                return (false, "Máy chủ phản hồi mã lỗi HTTP \(code). Vui lòng kiểm tra lại link.")
            }
            
            let decoded = try JSONDecoder().decode(SportCatalogResponse.self, from: data)
            let count = decoded.metas?.count ?? 0
            return (true, "Kết nối thành công! Đã tìm thấy \(count) sự kiện thể thao.")
        } catch {
            return (false, "Không thể kết nối đến máy chủ: \(error.localizedDescription)")
        }
    }
}
