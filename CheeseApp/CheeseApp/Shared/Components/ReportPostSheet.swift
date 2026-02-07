import SwiftUI

struct ReportPostSheet: View {
    let postId: UUID
    let postKind: PostKind

    @Environment(\.dismiss) private var dismiss

    @State private var reason: ReportReason = .inappropriate
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Report \(postKind.displayName) Post")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Help us keep the community safe. Reports are reviewed by moderation.")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textMuted)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Reason")
                                .font(.system(size: 14, weight: .semibold))

                            ForEach(ReportReason.allCases) { option in
                                Button {
                                    reason = option
                                } label: {
                                    HStack {
                                        Text(option.title)
                                            .font(.system(size: 14))
                                            .foregroundStyle(AppColors.textPrimary)
                                        Spacer()
                                        Image(systemName: reason == option ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(reason == option ? AppColors.link : AppColors.textMuted)
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details (optional)")
                                .font(.system(size: 14, weight: .semibold))

                            TextEditor(text: $details)
                                .frame(minHeight: 120)
                                .padding(8)
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
                                Text("Submit Report")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isSubmitting)

                        Spacer(minLength: 24)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
    }

    private func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            try await CommunityService.shared.submitPostReport(
                postId: postId,
                reason: reason,
                details: details
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
