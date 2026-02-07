//
//  ImagePicker.swift
//  CheeseApp
//
//  🎯 图片选择器组件
//

import SwiftUI
import PhotosUI

// ============================================
// 图片选择器
// ============================================

struct ImagePicker: View {
    @Binding var selectedImages: [UIImage]
    let maxCount: Int
    
    @State private var selectedItems: [PhotosPickerItem] = []
    
    init(selectedImages: Binding<[UIImage]>, maxCount: Int = 9) {
        self._selectedImages = selectedImages
        self.maxCount = maxCount
    }
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: maxCount,
            matching: .images
        ) {
            Label(L10n.tr("Add Photos", "選擇圖片"), systemImage: "photo.on.rectangle.angled")
                .foregroundStyle(AppColors.accentStrong)
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                selectedImages = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
}
