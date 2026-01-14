//
//  LanguageSelectionView.swift
//  safensound
//

import SwiftUI
import FirebaseAuth

struct LanguageSelectionView: View {
    @AppStorage("preferredLanguage") private var selectedLanguage: String = "en"
    
    let languages = [
        ("en", "English", "Ideal for overseas users worldwide."),
        ("zh-Hant", "繁體中文", "適合港澳台與喜愛繁體的用戶。"),
        ("zh-Hans", "简体中文", "适合中国大陆及全球简体用户。")
    ]
    
    var body: some View {
        List {
            ForEach(languages, id: \.0) { language in
                Button(action: {
                    selectLanguage(language.0)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.1)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(language.2)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selectedLanguage == language.0 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(String(localized: "Interface Language"))
    }
    
    private func selectLanguage(_ code: String) {
        // 1. Update AppStorage (UI updates immediately)
        selectedLanguage = code
        
        // 2. Silently sync with Firestore
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await FirebaseService.shared.updateLanguage(userId: userId, languageCode: code)
            } catch {
                print("Error syncing language preference: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        LanguageSelectionView()
    }
}
