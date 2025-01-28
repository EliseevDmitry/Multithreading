//
//  DownloadImageAsync.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 30.01.2025.
//


//www.picsum.photos - работает с VPN
import SwiftUI
import Combine

final class DownloadImageAsyncImageLoader {
    let url = URL(string: "https://picsum.photos/200")!
    
    
    //Загрузка изображения через клоужер:
    
    /*
     Пример как можно реализовать "красиво" функцию

    func downloadWithEscaping(completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> ()){
        URLSession.shared.dataTask(with: url){data, response, error in
            guard
                let data = data,
                let image = UIImage(data: data),
                let response = response as? HTTPURLResponse,
                response.statusCode >= 200 && response.statusCode < 300 else {
                completionHandler(nil, error)
                return
            }
            completionHandler(image, nil)
        }
        .resume()
     */
    
    private func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
        guard
            let data = data,
            let image = UIImage(data: data),
            let response = response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300 else {
            return nil
        }
        return image
    }

    func downloadWithEscaping(completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> ()){
        URLSession.shared.dataTask(with: url){[weak self] data, response, error in
            let image = self?.handleResponse(data: data, response: response)
            completionHandler(image, error)
        }
        .resume()
    }
    
    func downloadWithCombine() -> AnyPublisher<UIImage?, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(handleResponse)
            .mapError( {$0} )
            .eraseToAnyPublisher()
    }
    
    func downloadWithAsync() async throws -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url, delegate: nil)
            let image = handleResponse(data: data, response: response)
            return image
        } catch {
            throw error
        }
    }
}

final class DownloadImageAsyncViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    let loader = DownloadImageAsyncImageLoader()
    var cancebles = Set<AnyCancellable>()
    
    func fetchImage(){
        //self.image = UIImage(systemName: "heart.fill")
        loader.downloadWithEscaping { [weak self] image, error in
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
    
    func fetchImage2(){
        loader.downloadWithCombine()
            .sink { _ in
                
            } receiveValue: { [weak self] image in
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
            .store(in: &cancebles)
    }
    
    func fetchImage3() async {
        let image = try? await loader.downloadWithAsync()
        //требуется ОБЯЗАТЕЛЬНО! перейти на главный поток
        await MainActor.run {
            self.image = image
        }
    }
}

struct DownloadImageAsync: View {
    @StateObject private var viewModel = DownloadImageAsyncViewModel()
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            }
        }
        .onAppear{
            //viewModel.fetchImage()
            //viewModel.fetchImage2()
           Task{
                await viewModel.fetchImage3()
            }
        }
    }
}

#Preview {
    DownloadImageAsync()
}
