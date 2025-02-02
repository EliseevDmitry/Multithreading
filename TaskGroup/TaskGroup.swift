//
//  TaskGroup.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 02.02.2025.
//

import SwiftUI

final class TaskGroupDataManager {
    
    func fetchImagesWithAsyncLet() async throws -> [UIImage] {
        async let fetchImage1 = fetchImage(urlString: "https://picsum.photos/300")
        async let fetchImage2 = fetchImage(urlString: "https://picsum.photos/300")
        async let fetchImage3 = fetchImage(urlString: "https://picsum.photos/300")
        async let fetchImage4 = fetchImage(urlString: "https://picsum.photos/300")
        let (image1, image2, image3, image4) = await (try fetchImage1, try fetchImage2, try fetchImage3, try fetchImage4)
        return [image1, image2, image3, image4]
    }
    
    func fetchImagesWithTaskGroup() async throws -> [UIImage]{
        return try await withThrowingTaskGroup(of: UIImage.self) { group in
            var images: [UIImage] = []
            group.addTask {
                try await self.fetchImage(urlString: "https://picsum.photos/300")
            }
            group.addTask {
                try await self.fetchImage(urlString: "https://picsum.photos/300")
            }
            group.addTask {
                try await self.fetchImage(urlString: "https://picsum.photos/300")
            }
            group.addTask {
                try await self.fetchImage(urlString: "https://picsum.photos/300")
            }
            group.addTask {
                try await self.fetchImage(urlString: "https://picsum.photos/300")
            }
            group.addTask {
                try await self.fetchImage(urlString: "https://picsum.photos/300")
            }
            for try await image in group {
                images.append(image)
            }
            return images
        }
    }
    
    //улучшаем функцию fetchImagesWithTaskGroup
    func fetchImagesWithTaskGroup2() async throws -> [UIImage]{
        //добавляем несуществующий URL в массив
        let urlStringArray: [String] = [
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "",
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300"
        ]
        
        //меняем UIImage.self на UIImage?.self
        //return try await withTaskGroup - есть метод без "Throwing" - который не пробрасывает ошибки
        return try await withThrowingTaskGroup(of: UIImage?.self) { group in
            var images: [UIImage] = []
            //очень важная штука - резерв памяти под массив фотографий - увеличивает производительность!!!
            images.reserveCapacity(images.count)
            
            
            //меняем try на try? - что бы не была проброшена ошибка и вункция не была отменена "throws"
            for item in urlStringArray {
                //roup.addTask(priority: .background) - можно указать приоритет!!!
                group.addTask(priority: .background) {
                    try? await self.fetchImage(urlString: item)
                }
            }
            
            //делаем проверку на nil
            for try await image in group {
                if let newImage = image {
                    images.append(newImage)
                }
            }
            return images
        }
    }
    
    
    
   private func fetchImage(urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError.init(.badURL)
        }
        do{
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                return image
            } else {
                throw URLError.init(.badURL)
            }
        } catch {
            throw error
        }
    }
    
    
}

final class TaskGroupViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    let manager = TaskGroupDataManager()
    
    func getImages() async {
        if let images = try? await manager.fetchImagesWithAsyncLet() {
            self.images.append(contentsOf: images)
        }
    }
    
    func getImagesTaskGroup() async {
        if let images = try? await manager.fetchImagesWithTaskGroup() {
            self.images.append(contentsOf: images)
        }
    }
    
    func getImagesTaskGroup2() async {
        if let images = try? await manager.fetchImagesWithTaskGroup2() {
            self.images.append(contentsOf: images)
        }
    }
}

struct TaskGroup: View {
    @StateObject private var viewModel = TaskGroupViewModel()
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid (columns: columns) {
                    ForEach(viewModel.images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle("Task Group 😍")
        }
        .task {
            //Вызов функции -> fetchImagesWithAsyncLet
            //await viewModel.getImages()
            
            //Вызов функции -> getImagesTaskGroup
            //await viewModel.getImagesTaskGroup()
            //улучшеная функция
            await viewModel.getImagesTaskGroup2()
        }
    }
}

#Preview {
    TaskGroup()
}
