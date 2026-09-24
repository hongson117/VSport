//
//  SportsView.swift
//  VSport (Apple TV & iOS)
//
//  Màn hình chính duyệt và xem trực tiếp thể thao Full HD
//

import SwiftUI

public struct SportsView: View {
    @ObservedObject private var configManager = SportConfigManager.shared
    
    @State private var selectedCategoryId: String = "sports_live"
    @State private var events: [SportEvent] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    // Quản lý phát luồng video
    @State private var currentEvent: SportEvent?
    @State private var availableStreams: [SportStream] = []
    @State private var selectedStream: SportStream?
    @State private var showStreamPicker: Bool = false
    @State private var isFetchingStreams: Bool = false
    
    // Tự động làm mới danh sách mỗi 60 giây đối với danh mục Trực Tiếp
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Thanh chọn 7 Danh Mục Thể Thao
                categorySelectorBar
                
                // Lưới Sự Kiện Thể Thao
                ScrollView {
                    if isLoading && events.isEmpty {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if events.isEmpty {
                        emptyView
                    } else {
                        eventGridView
                    }
                }
            }
            .background(Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea())
            .navigationTitle("VSport Trực Tiếp")
            .task(id: selectedCategoryId) {
                await loadEvents(categoryId: selectedCategoryId)
            }
            .task(id: configManager.currentManifestURL) {
                // Tự động tải lại khi đổi nguồn trong Cài Đặt
                await loadEvents(categoryId: selectedCategoryId)
            }
            .onReceive(refreshTimer) { _ in
                if selectedCategoryId == "sports_live" {
                    Task {
                        await loadEvents(categoryId: selectedCategoryId, isSilent: true)
                    }
                }
            }
            // Trình chiếu video toàn màn hình native
            .fullScreenCover(item: $selectedStream) { stream in
                PlayerView(
                    streamUrl: stream.url,
                    title: currentEvent?.name ?? "Trực Tiếp Thể Thao",
                    subtitle: stream.displayTitle,
                    initialBitrate: stream.bitrateText,
                    initialFPS: stream.fpsText
                )
                .ignoresSafeArea()
            }
            // Hộp thoại chọn chất lượng luồng phát khi có nhiều độ phân giải
            .confirmationDialog(
                "Chọn Chất Lượng Luồng Phát",
                isPresented: $showStreamPicker,
                titleVisibility: .visible
            ) {
                ForEach(availableStreams) { stream in
                    Button(stream.displayTitle) {
                        selectedStream = stream
                    }
                }
            }
            .overlay {
                if isFetchingStreams {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.3)
                            Text("Đang kết nối luồng phát...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
    
    // MARK: - Thanh Chọn Danh Mục
    private var categorySelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SportCategory.allCategories) { cat in
                    Button {
                        selectedCategoryId = cat.id
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: cat.icon)
                            Text(cat.title)
                        }
                        .font(.system(size: 14, weight: selectedCategoryId == cat.id ? .bold : .medium))
                        .foregroundColor(selectedCategoryId == cat.id ? .white : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedCategoryId == cat.id ?
                                Color.red :
                                Color.white.opacity(0.08)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Lưới Sự Kiện
    private var eventGridView: some View {
        #if os(tvOS)
        let columns = [
            GridItem(.adaptive(minimum: 380, maximum: 460), spacing: 32)
        ]
        let horizPadding: CGFloat = 60
        #else
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let columns = [
            GridItem(.adaptive(minimum: isIPad ? 280 : 160), spacing: 16)
        ]
        let horizPadding: CGFloat = 16
        #endif
        
        return LazyVGrid(columns: columns, spacing: 24) {
            ForEach(events) { event in
                SportCard(event: event) {
                    Task {
                        await handleEventTap(event)
                    }
                }
            }
        }
        .padding(.horizontal, horizPadding)
        .padding(.top, 20)
        .padding(.bottom, 60)
    }
    
    // MARK: - Xử Lý Chạm Sự Kiện
    private func handleEventTap(_ event: SportEvent) async {
        isFetchingStreams = true
        currentEvent = event
        
        do {
            let streams = try await HighFlySportService.shared.fetchStreams(for: event.id)
            isFetchingStreams = false
            
            if streams.isEmpty {
                errorMessage = "Trận đấu chưa bắt đầu hoặc nguồn phát tạm thời gián đoạn."
            } else if streams.count == 1, let single = streams.first {
                selectedStream = single
            } else {
                availableStreams = streams
                showStreamPicker = true
            }
        } catch {
            isFetchingStreams = false
            errorMessage = "Lỗi tải luồng phát: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Tải Dữ Liệu Sự Kiện
    private func loadEvents(categoryId: String, isSilent: Bool = false) async {
        if !isSilent {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetched = try await HighFlySportService.shared.fetchCatalog(categoryId: categoryId)
            events = fetched
            isLoading = false
        } catch {
            if !isSilent {
                errorMessage = "Không thể tải danh mục: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Các Trạng Thái
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 100)
            ProgressView()
                .scaleEffect(1.5)
                .tint(.red)
            Text("Đang tải dữ liệu thể thao...")
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
    }
    
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.yellow)
            Text(msg)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Thử Lại") {
                Task {
                    await loadEvents(categoryId: selectedCategoryId)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 80)
            Image(systemName: "sportscourt")
                .font(.system(size: 44))
                .foregroundColor(.gray.opacity(0.5))
            Text("Hiện chưa có trận đấu nào trong danh mục này.")
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
    }
}
