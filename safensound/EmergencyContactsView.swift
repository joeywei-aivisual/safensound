//
//  EmergencyContactsView.swift
//  safensound
//

import SwiftUI

struct EmergencyContactsView: View {
    @State private var contacts: [EmergencyContact] = [
        EmergencyContact(email: "kevinway809@gmail.com")
    ]
    @State private var newContactEmail: String = ""
    
    var body: some View {
        VStack {
            List {
                ForEach(contacts) { contact in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(contact.email)
                                .font(.body)
                            if let name = contact.name {
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button(action: {
                            deleteContact(contact)
                        }) {
                            Text("刪除")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Add new contact
            HStack {
                TextField("family@example.com", text: $newContactEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addContact) {
                    Text("新增")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(newContactEmail.isEmpty)
            }
            .padding()
            
            Text("提示：可新增多位家人信箱，並告知他們留意活著麼的提醒郵件。")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .navigationTitle(String(localized: "Emergency Contacts"))
    }
    
    private func addContact() {
        guard !newContactEmail.isEmpty else { return }
        let newContact = EmergencyContact(email: newContactEmail)
        contacts.append(newContact)
        newContactEmail = ""
        // TODO: Save to Firestore
    }
    
    private func deleteContact(_ contact: EmergencyContact) {
        contacts.removeAll { $0.id == contact.id }
        // TODO: Update Firestore
    }
}

#Preview {
    NavigationView {
        EmergencyContactsView()
    }
}
