//
//  RentFilterOptions.swift
//  CheeseApp
//
//  🎯 租房筛选选项
//

import Foundation

// ============================================
// 筛选选项
// ============================================

struct RentFilterOptions {
    var searchQuery: String?
    var minPrice: Decimal?
    var maxPrice: Decimal?
    var propertyTypes: [RentPost.PropertyType] = []
    var minBedrooms: Int?
    var petsAllowed: Bool?
    var utilitiesIncluded: Bool?
    
    var hasFilters: Bool {
        searchQuery != nil || minPrice != nil || maxPrice != nil ||
        !propertyTypes.isEmpty || minBedrooms != nil ||
        petsAllowed != nil || utilitiesIncluded != nil
    }
    
    mutating func reset() {
        searchQuery = nil
        minPrice = nil
        maxPrice = nil
        propertyTypes = []
        minBedrooms = nil
        petsAllowed = nil
        utilitiesIncluded = nil
    }
}

// ============================================
// 排序选项
// ============================================

enum RentSortOption: String, CaseIterable {
    case newest = "newest"
    case priceAsc = "price_asc"
    case priceDec = "price_desc"
    
    var displayName: String {
        switch self {
        case .newest: return "最新发布"
        case .priceAsc: return "价格最低"
        case .priceDec: return "价格最高"
        }
    }
}
