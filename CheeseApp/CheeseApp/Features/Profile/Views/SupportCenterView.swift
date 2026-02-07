import SwiftUI

struct SupportCenterView: View {
    var body: some View {
        List {
            Section("Support") {
                NavigationLink {
                    FeedbackFormView()
                } label: {
                    Label("Send Feedback", systemImage: "bubble.left.and.exclamationmark.bubble.right.fill")
                }

                Link(destination: URL(string: "mailto:support@cheeseapp.dev")!) {
                    Label("Email Support", systemImage: "envelope.fill")
                }
            }

            Section("Notes") {
                Text("For urgent safety issues, use the Report button on posts.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.pageBackground)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeedbackFormView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var category: FeedbackCategory = .other
    @State private var message = ""
    @State private var contactEmail = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColors.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tell us what we should improve.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.textMuted)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 14, weight: .semibold))
                        Picker("Category", selection: $category) {
                            ForEach(FeedbackCategory.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.system(size: 14, weight: .semibold))
                        TextEditor(text: $message)
                            .frame(minHeight: 160)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contact Email (optional)")
                            .font(.system(size: 14, weight: .semibold))
                        TextField("you@example.com", text: $contactEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text("Submit Feedback")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.accent)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isSubmitting || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer(minLength: 24)
                }
                .padding(16)
            }
        }
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if contactEmail.isEmpty {
                contactEmail = authService.currentUser?.email ?? ""
            }
        }
    }

    private func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await CommunityService.shared.submitFeedback(
                category: category,
                message: message,
                contactEmail: contactEmail
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
