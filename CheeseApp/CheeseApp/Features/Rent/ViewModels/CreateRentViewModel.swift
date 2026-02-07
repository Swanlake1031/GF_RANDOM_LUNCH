//
//  CreateRentViewModel.swift
//  CheeseApp
//
//  📝 发布租房帖子 ViewModel
//

import SwiftUI

@MainActor
class CreateRentViewModel: ObservableObject {
    // 表单字段
    @Published var title = ""
    @Published var description = ""
    @Published var price = ""
    @Published var city = ""
    @Published var address = ""
    @Published var bedrooms = 1
    @Published var bathrooms = 1
    @Published var propertyType = "apartment"
    @Published var availableDate = Date()
    @Published var amenities: Set<String> = []
    @Published var promotionPlan: PostPromotionPlan = .none
    
    // 状态
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    @Published var lastCreatedPostId: UUID?
    
    private let service = RentService.shared
    
    var isValid: Bool {
        !title.isEmpty && !price.isEmpty && !city.isEmpty
    }
    
    func submit() async {
        guard isValid else {
            errorMessage = "请填写必填字段"
            return
        }
        
        guard let priceValue = Double(price) else {
            errorMessage = "请输入有效的价格"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let postId = try await service.createPost(
                title: title,
                description: description,
                propertyType: propertyType,
                bedrooms: bedrooms,
                bathrooms: bathrooms,
                price: priceValue,
                city: city,
                address: address,
                availableFrom: availableDate,
                amenities: Array(amenities),
                highlightType: promotionPlan.highlightType,
                pinnedUntil: promotionPlan.pinnedUntil
            )
            lastCreatedPostId = postId
            isSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func reset() {
        title = ""
        description = ""
        price = ""
        city = ""
        address = ""
        bedrooms = 1
        bathrooms = 1
        propertyType = "apartment"
        availableDate = Date()
        amenities = []
        promotionPlan = .none
        errorMessage = nil
        isSuccess = false
        lastCreatedPostId = nil
    }
}
