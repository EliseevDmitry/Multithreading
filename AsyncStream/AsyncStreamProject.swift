//
//  AsyncStream.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 12.02.2025.
//


//основная идея в том что Continuation - мог преобразовать в async/await - одно замыкание (одно действие), а AsyncStream - это может делать (очень нужная и удобная вещь!!!)
import SwiftUI
import Foundation

class AsyncStreamDataManager {
    /*
    без проброса ошибки
    func getAsyncStream() -> AsyncStream<Int> {
        AsyncStream(Int.self) { [weak self] continuation in
            self?.getFakeData(completion: { value in
                continuation.yield(value)
            }, onFinish: {
                continuation.finish()
            })
        }
    }
     

    
    func getFakeData(completion: @escaping (_ value: Int) -> Void, onFinish: @escaping () -> Void) {
        let items: [Int] = [1, 2, 4, 5, 6, 7, 8, 9]
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)){
                completion(item)
                
                if item == items.last {
                    onFinish()
                    
                }
            }
        }
    }
     */
    
    func getAsyncStream() -> AsyncThrowingStream<Int, Error> {
        AsyncThrowingStream(Int.self) { [weak self] continuation in
            self?.getFakeData(completion: { value in
                continuation.yield(value)
            }, onFinish: {error in
                if let error {
                    print(error)
                } else {
                    continuation.finish()
                }
            })
        }
    }
     

    
    func getFakeData(completion: @escaping (_ value: Int) -> Void, onFinish: @escaping (_ error: Error?) -> Void) {
        let items: [Int] = [1, 2, 4, 5, 6, 7, 8, 9]
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)){
                completion(item)
                print("New data \(item)")
                if item == items.last {
                    onFinish(nil)
                }
            }
        }
    }
}
    
    
    


@MainActor
final class AsyncStreamViewModel: ObservableObject {
    let manager = AsyncStreamDataManager()
    @Published private(set) var currentNumber: Int = 0
    
    func onViewAppear() {
        manager.getFakeData { [weak self] value in
            self?.currentNumber = value
        } onFinish: {error in 
            print("Finish")
        }

    }
    /*
    без проброса ошибки
    func onViewApperAsync() {
        Task {
            for await value in manager.getAsyncStream() {
                currentNumber = value
            }
        }
    }
     */
    func onViewApperAsync() {
        let task = Task {
            do {
                for try await value in
                    /*
                     еще одна фишка - схожие!!! методы combine - к примеру .dropFirst(3), начнет с 4 элемента
                     manager.getAsyncStream().dropFirst(3)
                     "Swift Async Algorithms"
                     */
                    manager.getAsyncStream().dropFirst(3) {
                    currentNumber = value
                }
            } catch {
               print(error)
            }
        }
        
        /*
         print("Cancel Task") - эта история показывает - что если мы даже остановили задачу Task -> поток данных AsyncStream продолжает выполняться (c этим надо быть очень аккуратным!!!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            task.cancel()
            print("Cancel Task")
        }
         */
    }
    
}

struct AsyncStreamProject: View {
    @StateObject private var viewModel = AsyncStreamViewModel()
    var body: some View {
        Text("\(viewModel.currentNumber)")
        /*
         на замыкании
            .onAppear{
                viewModel.onViewAppear()
            }
         */
        
            .onAppear{
             viewModel.onViewApperAsync()
            }
    }
}

#Preview {
    AsyncStreamProject()
}
