//
//  DailyReminderView.swift
//  safensound
//

import SwiftUI

struct DailyReminderView: View {
    @State private var selectedThreshold: Int = 72
    @State private var dailyReminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 55)) ?? Date()
    @State private var showingSaveAlert = false
    
    let thresholds = [24, 48, 72]
    
    var body: some View {
        Form {
            Section(header: Text("每日提醒")) {
                Picker("Check-in Threshold", selection: $selectedThreshold) {
                    ForEach(thresholds, id: \.self) { threshold in
                        Text("\(threshold) 小時").tag(threshold)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("每日提醒簽到", isOn: $dailyReminderEnabled)
                
                if dailyReminderEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section {
                Button(action: saveSettings) {
                    HStack {
                        Spacer()
                        Text("儲存設定並同步")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
            
            Section {
                Text("提示：可新增多位家人信箱，並告知他們留意活著麼的提醒郵件。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("開啟每日提醒後，會在您設定的時間推送本地通知提醒您簽到。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("每日提醒")
        .alert("Settings Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        }
        .onChange(of: dailyReminderEnabled) { enabled in
            if enabled {
                Task {
                    await NotificationService.shared.scheduleDailyReminder(at: reminderTime)
                }
            } else {
                NotificationService.shared.cancelDailyReminder()
            }
        }
    }
    
    private func saveSettings() {
        // TODO: Save to Firestore
        if dailyReminderEnabled {
            Task {
                await NotificationService.shared.scheduleDailyReminder(at: reminderTime)
            }
        }
        showingSaveAlert = true
    }
}

#Preview {
    NavigationView {
        DailyReminderView()
    }
}
