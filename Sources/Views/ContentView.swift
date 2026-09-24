//
//  ContentView.swift
//  VSport (Apple TV & iOS)
//
//  Giao diện chính phân tab Thể Thao và Cài Đặt Nguồn Phát
//

import SwiftUI

public struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            SportsView()
                .tabItem {
                    Label("Trực Tiếp", systemImage: "sportscourt.fill")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Cài Đặt", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(.red)
    }
}
