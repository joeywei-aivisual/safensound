//
//  SettingsView.swift
//  safensound
//

import SwiftUI

struct SettingsView: View {
    @State private var userProfile: UserProfile?
    
    var body: some View {
        List {
            // Settings Overview Card
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("今日設定概覽")
                        .font(.headline)
                    
                    if let profile = userProfile {
                        Text("已新增 \(profile.emergencyContacts.count) 位緊急聯絡人")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("提醒閾值：\(profile.checkInThreshold) 小時未簽到")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("每日提醒：\(profile.dailyReminderEnabled ? "已開啟" : "未開啟")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Profile Section
            Section {
                NavigationLink(destination: PersonalInfoView()) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(String(localized: "Personal Information"))
                                .font(.headline)
                            Text(userProfile?.name ?? "Joey")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Emergency Contacts Section
            Section {
                NavigationLink(destination: EmergencyContactsView()) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(String(localized: "Emergency Contacts"))
                                .font(.headline)
                            Text("已新增 \(userProfile?.emergencyContacts.count ?? 0) 位緊急聯絡人")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Daily Reminder Section
            Section {
                NavigationLink(destination: DailyReminderView()) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("每日提醒")
                                .font(.headline)
                            Text("提醒閾值：\(userProfile?.checkInThreshold ?? 72) 小時未簽到")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Interface Language Section
            Section {
                NavigationLink(destination: LanguageSelectionView()) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.purple)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("介面語言")
                                .font(.headline)
                            Text("繁體中文")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Settings"))
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
