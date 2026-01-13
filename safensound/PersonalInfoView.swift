//
//  PersonalInfoView.swift
//  safensound
//

import SwiftUI

struct PersonalInfoView: View {
    @State private var name: String = "Joey"
    @State private var email: String = "kevinway809@gmail.com"
    @State private var showingSaveAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("個人資訊")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        Text("Save")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Personal Information"))
        .alert("Profile Saved", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) {}
        }
    }
    
    private func saveProfile() {
        // TODO: Save to Firestore
        showingSaveAlert = true
    }
}

#Preview {
    NavigationView {
        PersonalInfoView()
    }
}
