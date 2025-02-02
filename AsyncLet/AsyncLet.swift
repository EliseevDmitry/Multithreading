//
//  AsyncLet.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 02.02.2025.
//

import SwiftUI

struct AsyncLet: View {
    @State private var images: [UIImage] = []
    @State private var title: String = "Async Let 😍"
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    let url = URL(string: "https://picsum.photos/200")!
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid (columns: columns) {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle(title)
            .onAppear{
                /*
                 Не эффективное решение 1
                 //решение 1 - с 1 по 6 фотографию выполнение кода будет идти последовательно, тем самым это не эффективно и "гонимо"
                 Task {
                 do {
                 let image1 = try await fetchImage()
                 self.images.append(image1)
                 
                 let image2 = try await fetchImage()
                 self.images.append(image2)
                 
                 let image3 = try await fetchImage()
                 self.images.append(image3)
                 
                 let image4 = try await fetchImage()
                 self.images.append(image4)
                 
                 let image5 = try await fetchImage()
                 self.images.append(image5)
                 
                 let image6 = try await fetchImage()
                 self.images.append(image6)
                 } catch {
                 
                 }
                 */
                
                /*
                 Второе неэффективное решение - ускоренное в 2 раза
                 Task {
                 do {
                 let image1 = try await fetchImage()
                 self.images.append(image1)
                 
                 let image2 = try await fetchImage()
                 self.images.append(image2)
                 
                 let image3 = try await fetchImage()
                 self.images.append(image3)
                 } catch {
                 
                 }
                 }
                 Task {
                 do {
                 let image4 = try await fetchImage()
                 self.images.append(image4)
                 
                 let image5 = try await fetchImage()
                 self.images.append(image5)
                 
                 let image6 = try await fetchImage()
                 self.images.append(image6)
                 } catch {
                 
                 }
                 }
                 */
                
                /*
                 //Идеальное решение по загрузки изображений - все в один раз, но вот что делать если фоток 100 или 1000?
                 Task {
                 do {
                 let image1 = try await fetchImage()
                 self.images.append(image1)
                 } catch {
                 
                 }
                 }
                 Task {
                 do {
                 let image2 = try await fetchImage()
                 self.images.append(image2)
                 } catch {
                 
                 }
                 }
                 Task {
                 do {
                 let image3 = try await fetchImage()
                 self.images.append(image3)
                 } catch {
                 
                 }
                 }
                 Task {
                 do {
                 let image4 = try await fetchImage()
                 self.images.append(image4)
                 } catch {
                 
                 }
                 }
                 Task {
                 do {
                 let image5 = try await fetchImage()
                 self.images.append(image5)
                 } catch {
                 
                 }
                 }
                 Task {
                 do {
                 let image6 = try await fetchImage()
                 self.images.append(image6)
                 } catch {
                 
                 }
                 }
                 */
                
                
                /*
                 async let - это история для 2-4-6-8 запросов, но если нам необходимо работать с 50-100-1000 запросов то мы должны использовать - Task Group
                 */
                
                Task {
                    //в рамках async let могут быть разные типы данных
                    do {
                        async let fetchImage1 = fetchImage()
                        async let fetchImage2 = fetchImage()
                        async let fetchImage3 = fetchImage()
                        async let fetchImage4 = fetchImage()
                        async let fetchImage5 = fetchImage()
                        async let fetchImage6 = fetchImage()
                        async let fetchTitle = fetchTitle()
                        
                        //в fetchTitle не используем try потому что в функции func fetchTitle() async -> String {} - нету throws
                        
                        let (image1, image2, image3, image4, image5, image6, title) = await (try fetchImage1, try fetchImage2, try fetchImage3, try fetchImage4, try fetchImage5, try fetchImage6, fetchTitle)
                        self.images.append(contentsOf: [image1, image2, image3, image4, image5, image6])
                        
                        self.title = title
                    } catch {
                        
                    }
                }
                
            }
        }
    }
    func fetchTitle() async -> String {
        return "NEW TITLE"
    }
    
    private func fetchImage() async throws -> UIImage {
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

#Preview {
    AsyncLet()
}
