//
//  RentFormatter.swift
//  CheeseApp
//
//  🎯 租房信息格式化工具
//

import Foundation

// ============================================
// 租房格式化工具
// ============================================

enum RentFormatter {
    
    /// 获取房型规格显示
    static func getDisplaySpec(bedrooms: Int?, bathrooms: Decimal?, specs: String?) -> String {
        if let specs = specs, !specs.isEmpty {
            return specs
        }
        
        guard let bedrooms = bedrooms else {
            return "详情待补充"
        }
        
        let bathroomStr: String
        if let bathrooms = bathrooms {
            bathroomStr = "\(bathrooms)卫"
        } else {
            bathroomStr = ""
        }
        
        return "\(bedrooms)室\(bathroomStr)"
    }
    
    /// 获取价格/卧室
    static func getPricePerBedroom(price: Decimal, bedrooms: Int?) -> Decimal? {
        guard let bedrooms = bedrooms, bedrooms > 0 else {
            return nil
        }
        return price / Decimal(bedrooms)
    }
}
