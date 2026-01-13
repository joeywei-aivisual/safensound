//
//  LanguageSelectionView.swift
//  safensound
//

import SwiftUI

struct LanguageSelectionView: View {
    @State private var selectedLanguage: String = "zh-Hant"
    
    let languages = [
        ("zh-Hans", "简体中文", "适合中国大陆及全球简体用户。"),
        ("zh-Hant", "繁體中文", "適合港澳台與喜愛繁體的用戶。"),
        ("en", "English", "Ideal for overseas users worldwide.")
    ]
    
    var body: some View {
        List {
            ForEach(languages, id: \.0) { language in
                Button(action: {
                    selectedLanguage = language.0
                    // TODO: Update app language and save to Firestore
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
                                .foregroundColor(.pink)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("介面語言")
    }
}

#Preview {
    NavigationView {
        LanguageSelectionView()
    }
}
