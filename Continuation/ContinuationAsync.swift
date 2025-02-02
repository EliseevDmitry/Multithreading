//
//  ContinuationAsync.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 02.02.2025.
//

import SwiftUI

final class ContinuationAsyncNetworkManager {
    
    func getData(url: URL) async throws -> Data {
        do {
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            return data
        } catch {
            throw error
        }
    }
    
    func getData2(url: URL) async throws -> Data {
        
        //преобразование иных асинхронных запросов в async/await
        //withCheckedThrowingContinuation - прокидывает ошибку (throws)
        //withCheckedContinuation - не прокидывает ошибку func getData2(url: URL) async -> Data
        
        //ОЧЕНЬ ВАЖНО! - You must invoke the continuation’s resume method exactly once.
        
        /*
         4-функции:
         Небезопасная - требуется на себя брать проверку за все:
         withUnsafeContinuation(<#T##fn: (UnsafeContinuation<T, Never>) -> Void##(UnsafeContinuation<T, Never>) -> Void#>)
         Безопасная:
         withCheckedContinuation(<#T##body: (CheckedContinuation<T, Never>) -> Void##(CheckedContinuation<T, Never>) -> Void#>)
         Небезопасная с пробросом ошибки throws:
         withUnsafeThrowingContinuation(<#T##fn: (UnsafeContinuation<T, any Error>) -> Void##(UnsafeContinuation<T, any Error>) -> Void#>)
         Безопасная с пробросом ошибки throws:
         withCheckedThrowingContinuation(<#T##body: (CheckedContinuation<T, any Error>) -> Void##(CheckedContinuation<T, any Error>) -> Void#>)
         */
        
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    continuation.resume(returning: data)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: URLError(.badURL))
                }
            }
            .resume()
        }
    }
    
    private func getHeartImageFromDataBase(completionHandler: @escaping ((_ image: UIImage) ->())){
        DispatchQueue.main.asyncAfter(deadline: .now() + 5
        ){
            completionHandler(UIImage(systemName: "heart.fill")!)
        }
    }
    
    //преобразуем функцию getHeartImageFromDataBase() в async/await
    func getHeartFromDataBase() async -> UIImage {
        return await withCheckedContinuation { continuation in
            getHeartImageFromDataBase { image in
                continuation.resume(returning: image)
            }
        }
    }
    
}

final class ContinuationAsyncViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    let networkManager = ContinuationAsyncNetworkManager()
    
    func getImage() async {
        guard let url = URL(string: "https://picsum.photos/300") else { return }
        do {
            //различные варианты использования:
            //networkManager.getData(url: url)
            //networkManager.getData2(url: url)
            let data = try await networkManager.getData2(url: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.image = image
                }
            }
        } catch {
            print(error)
        }
    }
    
    func getHeartImage() async {
        let image = await networkManager.getHeartFromDataBase()
        await MainActor.run {
            self.image = image
        }
    }
}

struct ContinuationAsync: View {
    @StateObject private var viewModel = ContinuationAsyncViewModel()
    var body: some View {
        ZStack{
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        .task {
            //await viewModel.getImage()
            await viewModel.getHeartImage()
        }
    }
}

#Preview {
    ContinuationAsync()
}
