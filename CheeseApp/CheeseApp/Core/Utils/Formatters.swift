//
//  Formatters.swift
//  CheeseApp
//
//  🎯 格式化工具
//

import Foundation

// ============================================
// 格式化工具类
// ============================================

enum Formatters {
    
    // ============================================
    // 价格格式化
    // ============================================
    
    /// 格式化价格
    static func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$\(price)"
    }
    
    /// 格式化价格（Double）
    static func formatPrice(_ price: Double) -> String {
        return formatPrice(Decimal(price))
    }
    
    // ============================================
    // 时间格式化
    // ============================================
    
    /// 相对时间格式化
    static func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // ============================================
    // 文本处理
    // ============================================
    
    /// 截断文本
    static func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        let index = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<index]) + "..."
    }
}
