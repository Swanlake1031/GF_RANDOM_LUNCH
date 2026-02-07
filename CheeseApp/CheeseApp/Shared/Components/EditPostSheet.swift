import SwiftUI

struct EditPostSheet: View {
    let post: UserPostSummary
    let onSave: (EditableUserPostPayload) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var userPostsService = UserPostsService()

    @State private var title: String
    @State private var description: String
    @State private var priceText: String
    @State private var rentLocation: String
    @State private var rentBedrooms: Int
    @State private var rentBathrooms: Double
    @State private var rentPropertyType: String
    @State private var includeAvailableDate: Bool
    @State private var availableDate: Date
    @State private var amenitiesText: String
    @State private var isLoadingRentDetails = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(post: UserPostSummary, onSave: @escaping (EditableUserPostPayload) async throws -> Void) {
        self.post = post
        self.onSave = onSave
        _title = State(initialValue: post.title)
        _description = State(initialValue: post.description)
        _priceText = State(initialValue: post.price.map { String(format: "%.0f", $0) } ?? "")
        _rentLocation = State(initialValue: post.subtitle)
        _rentBedrooms = State(initialValue: 1)
        _rentBathrooms = State(initialValue: 1)
        _rentPropertyType = State(initialValue: "apartment")
        _includeAvailableDate = State(initialValue: false)
        _availableDate = State(initialValue: Date())
        _amenitiesText = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        fieldTitle("Title")
                        TextField("Title", text: $title)
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        fieldTitle("Description")
                        TextEditor(text: $description)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if post.kind.supportsPriceEditing {
                            fieldTitle("Price")
                            TextField("Price", text: $priceText)
                                .keyboardType(.decimalPad)
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            priceChangePreview
                        }

                        if post.kind == .rent {
                            rentFieldsSection
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.black)
                                }
                                Text("Save Changes")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isSaving)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await loadRentDetailsIfNeeded()
            }
        }
    }

    private var rentFieldsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                fieldTitle("Rent Details")
                if isLoadingRentDetails {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            fieldTitle("Location")
            TextField("Address or area", text: $rentLocation)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    fieldTitle("Bedrooms")
                    Stepper(value: $rentBedrooms, in: 0...20) {
                        Text("\(rentBedrooms)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    fieldTitle("Bathrooms")
                    Stepper(value: $rentBathrooms, in: 0...20, step: 0.5) {
                        Text(String(format: "%.1f", rentBathrooms))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            fieldTitle("Property Type")
            Picker("Property Type", selection: $rentPropertyType) {
                Text("Apartment").tag("apartment")
                Text("House").tag("house")
                Text("Studio").tag("studio")
                Text("Room").tag("room")
                Text("Condo").tag("condo")
            }
            .pickerStyle(.segmented)
            .padding(8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Toggle("Set Available Date", isOn: $includeAvailableDate)
                .font(.system(size: 14, weight: .medium))
                .tint(AppColors.link)

            if includeAvailableDate {
                DatePicker(
                    "Available Date",
                    selection: $availableDate,
                    displayedComponents: .date
                )
                .font(.system(size: 14, weight: .medium))
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            fieldTitle("Amenities (comma separated)")
            TextField("WiFi, Parking, Pets allowed", text: $amenitiesText)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var priceChangePreview: some View {
        Group {
            if let original = post.price,
               let edited = Double(priceText),
               abs(original - edited) > 0.0001 {
                HStack(spacing: 8) {
                    Text(formattedPrice(original))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                        .strikethrough(true, color: AppColors.textMuted)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textMuted)

                    Text(formattedPrice(edited))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.link)
                }
                .padding(.top, 2)
            }
        }
    }

    private func fieldTitle(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.textPrimary)
    }

    private func formattedPrice(_ value: Double) -> String {
        switch post.kind {
        case .rent:
            return "$\(Int(value))/mo"
        case .ride:
            return "$\(Int(value))/seat"
        case .secondhand:
            return "$\(Int(value))"
        case .team, .forum:
            return "$\(Int(value))"
        }
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let normalizedPrice: Double?
            if post.kind.supportsPriceEditing {
                let trimmed = priceText.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    normalizedPrice = nil
                } else if let parsed = Double(trimmed) {
                    normalizedPrice = parsed
                } else {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid price"])
                }
            } else {
                normalizedPrice = nil
            }

            try await onSave(
                EditableUserPostPayload(
                    id: post.id,
                    kind: post.kind,
                    title: title,
                    description: description,
                    price: normalizedPrice,
                    rentDetails: post.kind == .rent
                    ? RentEditableFields(
                        location: rentLocation,
                        bedrooms: rentBedrooms,
                        bathrooms: rentBathrooms,
                        propertyType: rentPropertyType,
                        availableFrom: includeAvailableDate ? availableDate : nil,
                        amenities: amenitiesText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                    )
                    : nil
                )
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadRentDetailsIfNeeded() async {
        guard post.kind == .rent, !isLoadingRentDetails else { return }
        isLoadingRentDetails = true
        defer { isLoadingRentDetails = false }

        do {
            let details = try await userPostsService.fetchRentEditFields(postId: post.id)
            rentLocation = details.location
            rentBedrooms = max(details.bedrooms, 0)
            rentBathrooms = max(details.bathrooms, 0)
            rentPropertyType = details.propertyType
            if let date = details.availableFrom {
                includeAvailableDate = true
                availableDate = date
            }
            amenitiesText = details.amenities.joined(separator: ", ")
        } catch {
            // Keep fallback values when loading extra fields fails.
        }
    }
}
