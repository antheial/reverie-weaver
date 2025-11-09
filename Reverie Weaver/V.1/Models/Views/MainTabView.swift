//
//  MainTabView.swift
//  ReverieWeaver
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // ⭐ ADD THIS LINE - Beautiful time-based background
                       ReverieWeaverBackground()
            // Main content
            TabView(selection: $selectedTab) {
                DeskView()
                    .tag(0)
                
                LoomView()
                    .tag(1)
                
                ArchiveView()
                    .tag(2)
                
                ProfileView()
                    .tag(3)
            }

            // Custom floating tab bar
            HStack(spacing: 0) {
                CustomTabButton(
                    icon: "house.fill",
                    label: "Desk",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                CustomTabButton(
                    icon: "water.waves",
                    label: "Loom",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                CustomTabButton(
                    icon: "archivebox.fill",
                    label: "Archive",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
                
                CustomTabButton(
                    icon: "person.circle",
                    label: "Profile",
                    isSelected: selectedTab == 3
                ) {
                    selectedTab = 3
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 25)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct CustomTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black : .black.opacity(0.4))
                    .frame(height: 22)
                
                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .black : .black.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Circle()
                    .fill(Color.black.opacity(isSelected ? 0.08 : 0))
                    .frame(width: 45, height: 45)
                    .blur(radius: isSelected ? 8 : 0)
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}

#Preview {
    MainTabView()
}
