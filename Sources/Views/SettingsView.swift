//
//  SettingsView.swift
//  VSport (Apple TV & iOS)
//
//  Cài Đặt Nguồn Phát Thể Thao (BYOK - Tự Mua Tự Dùng):
//  - Quản lý link Addon / JSON Manifest (mặc định sports.highfly.to hoặc link Premium).
//  - Kiểm tra kết nối thời gian thực.
//  - Tự động đồng bộ iCloud giữa iPhone và Apple TV.
//

import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var configManager = SportConfigManager.shared
    
    @State private var inputURL: String = ""
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    @State private var isSuccess: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - 1. Nguồn Phát Hiện Tại
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Trạng Thái Nguồn")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(configManager.isUsingDefault ? "Nguồn Mặc Định (Free 1080p)" : "Gói Riêng (Premium)")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Text(configManager.currentManifestURL)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("NGUỒN PHÁT HIỆN TẠI")
                }
                
                // MARK: - 2. Tự Điền Link Addon Cá Nhân
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nhập Link Addon / JSON Manifest:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("https://premium.highfly.to/.../manifest.json", text: $inputURL)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            #if !os(tvOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            #endif
                        
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await saveAndTest()
                                }
                            } label: {
                                HStack {
                                    if isTesting {
                                        ProgressView()
                                            .padding(.trailing, 4)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    Text("Lưu & Kiểm Tra")
                                        .fontWeight(.bold)
                                }
                            }
                            #if !os(tvOS)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            #endif
                            .disabled(isTesting || inputURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            Button {
                                configManager.resetToDefault()
                                inputURL = ""
                                testResult = "Đã khôi phục nguồn miễn phí mặc định."
                                isSuccess = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Khôi Phục Mặc Định")
                                }
                            }
                            #if !os(tvOS)
                            .buttonStyle(.bordered)
                            #endif
                            .disabled(isTesting || configManager.isUsingDefault)
                        }
                        
                        if let result = testResult {
                            HStack(spacing: 6) {
                                Image(systemName: isSuccess ? "checkmark.circle" : "exclamationmark.triangle")
                                    .foregroundColor(isSuccess ? .green : .red)
                                Text(result)
                                    .font(.caption)
                                    .foregroundColor(isSuccess ? .green : .red)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("CẤU HÌNH LINK PREMIUM (BYOK)")
                } footer: {
                    Text("Bạn có thể dán link manifest đầy đủ hoặc link rút gọn. Ứng dụng sẽ tự động phân giải và tải danh mục.")
                }
                
                // MARK: - 3. Hướng Dẫn Tự Mua & Sử Dụng
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        guideRow(step: "1", text: "Mặc định ứng dụng phát miễn phí các kênh thể thao sắc nét đến 1080p FHD.")
                        guideRow(step: "2", text: "Nếu bạn tự mua gói HighFly Premium cá nhân, sao chép link Addon Manifest (dạng https://premium.highfly.to/.../manifest.json).")
                        guideRow(step: "3", text: "Dán link vào ô trên rồi bấm 'Lưu & Kiểm Tra'.")
                        guideRow(step: "4", text: "📱 Đồng bộ iCloud: Nếu iPhone và Apple TV dùng chung tài khoản iCloud, bạn chỉ cần dán link trên iPhone, Apple TV sẽ tự động nhận mà không cần gõ remote!")
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("HƯỚNG DẪN SỬ DỤNG")
                }
                
                // MARK: - 4. Thông Tin Ứng Dụng
                Section {
                    LabeledContent("Tên Ứng Dụng", value: "VSport")
                    LabeledContent("Phiên Bản", value: "1.0.0")
                    LabeledContent("Trình Phát", value: "Apple Native AVPlayer (Full HD 50 FPS)")
                    LabeledContent("Nền Tảng", value: "Apple TV (tvOS) & iPhone / iPad (iOS)")
                } header: {
                    Text("THÔNG TIN")
                }
            }
            .navigationTitle("Cài Đặt Nguồn Phát")
            .onAppear {
                if !configManager.isUsingDefault {
                    inputURL = configManager.currentManifestURL
                }
            }
        }
    }
    
    private func guideRow(step: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.red)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
    
    private func saveAndTest() async {
        isTesting = true
        testResult = nil
        
        let trimmed = inputURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let (success, message) = await configManager.testConnection(urlString: trimmed)
        
        isSuccess = success
        testResult = message
        isTesting = false
        
        if success {
            configManager.saveCustomURL(trimmed)
        }
    }
}
