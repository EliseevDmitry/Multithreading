//
//  PhotoPickerProject.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 08.02.2025.
//

import SwiftUI
//библиотека для фотопикера на SUI
import PhotosUI

@MainActor
final class PhotoPickerProjectViewModel: ObservableObject {
    @Published private(set) var selectedImage: UIImage? = nil
    //нельзя делать другой тип данных - потому что мы не знаем что выберет пользователь (фото или видео)
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            setImage(from: imageSelection)
        }
    }
    
    @Published private(set) var selectedImages: [UIImage] = []
    @Published var imagesSelection: [PhotosPickerItem] = [] {
        didSet {
            setImages(from: imagesSelection)
        }
    }
    
    private func setImage(from selection: PhotosPickerItem?) {
        guard let selection else { return }
        /*
         Без пробрасывания ошибки
         Task {
         if let data = try? await selection.loadTransferable(type: Data.self){
         if let uiImage =
         UIImage(data: data) {
         selectedImage = uiImage
         }
         }
         }
         */
        
        Task{
            do{
                let data = try? await selection.loadTransferable(type: Data.self)
                guard let data, let image = UIImage(data: data) else {
                    throw URLError(.badServerResponse)
                }
                selectedImage = image
            } catch {
                print(error)
            }
            
        }
    }
    
    //функция без проверок (для выбора [] фотографий)
    private func setImages(from selections: [PhotosPickerItem]) {
        Task{
            var images: [UIImage] = []
            for selection in selections {
                if let data = try? await selection.loadTransferable(type: Data.self) {
                    if let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
            }
            selectedImages = images
        }
    }
    
}

struct PhotoPickerProject: View {
    @StateObject private var viewModel = PhotoPickerProjectViewModel()
    var body: some View {
        VStack(spacing: 40) {
            Text("Test Photo & Photos")
                .padding(.top, 20)
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .cornerRadius(10)
            }
            PhotosPicker(selection: $viewModel.imageSelection, matching: .images) {
                Text("Выбери фото!")
            }
            if !viewModel.selectedImages.isEmpty {
                ScrollView{
                    HStack (spacing: 10){
                        ForEach (viewModel.selectedImages, id: \.self) {image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .cornerRadius(10)
                        }
                    }
                }
                .frame(width: .infinity, height: 50)
            }
        
            //matching - тип файлов (.all и .any - можно настраивать)
            PhotosPicker(selection: $viewModel.imagesSelection, matching: .images) {
                Text("Выбери фото!")
            }
            Spacer()
        }
    }
}

#Preview {
    PhotoPickerProject()
}
