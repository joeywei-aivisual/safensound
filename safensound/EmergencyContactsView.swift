//
//  EmergencyContactsView.swift
//  safensound
//

import SwiftUI
import FirebaseAuth

struct EmergencyContactsView: View {
    @State private var contacts: [EmergencyContact] = []
    @State private var newContactEmail: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
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
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                        .disabled(isSaving)
                    }
                }
            }
            
            // Add new contact
            HStack {
                TextField("family@example.com", text: $newContactEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isSaving)
                
                Button(action: addContact) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(8)
                    } else {
                        Text("Add")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(canAddContact ? Color.blue : Color.gray)
                            .cornerRadius(8)
                    }
                }
                .disabled(!canAddContact || isSaving)
            }
            .padding()
            
            Text("Tip: You can add multiple family emails. Please inform them to look out for Safe & Sound emails.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .navigationTitle(String(localized: "Emergency Contacts"))
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .task {
            await loadContacts()
        }
    }
    
    private var canAddContact: Bool {
        !newContactEmail.isEmpty && isValidEmail(newContactEmail)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func loadContacts() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        do {
            let profile = try await FirebaseService.shared.fetchUserProfile(userId: userId)
            contacts = profile.emergencyContacts
        } catch {
            print("Error loading contacts: \(error)")
        }
    }
    
    private func addContact() {
        guard canAddContact else { return }
        
        let newContact = EmergencyContact(email: newContactEmail)
        let updatedContacts = contacts + [newContact]
        
        saveContacts(updatedContacts) {
            contacts.append(newContact)
            newContactEmail = ""
        }
    }
    
    private func deleteContact(_ contact: EmergencyContact) {
        var updatedContacts = contacts
        updatedContacts.removeAll { $0.id == contact.id }
        
        saveContacts(updatedContacts) {
            contacts = updatedContacts
        }
    }
    
    private func saveContacts(_ newContacts: [EmergencyContact], onSuccess: @escaping () -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isSaving = true
        
        Task {
            do {
                try await FirebaseService.shared.updateEmergencyContacts(userId: userId, contacts: newContacts)
                onSuccess()
            } catch {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
            isSaving = false
        }
    }
}

#Preview {
    NavigationView {
        EmergencyContactsView()
    }
}
