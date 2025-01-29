//
//  AsyncAwait.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 30.01.2025.
//

import SwiftUI

final class AsyncAwaitViewModel: ObservableObject {
    @Published var dataArray: [String] = []
    
    func addTitle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dataArray.append("Title1: \(Thread.current)")
        }
    }
    
    func addTitle2() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            let title = "Title1: \(Thread.current)"
            DispatchQueue.main.async {
                self.dataArray.append(title)
                
                self.dataArray.append("Title3: \(Thread.current)")
            }
        }
    }
    
    func addAuthor1() async {
        /*
         с введением swift6 нельзя использовать в асинхронной функции "Thread.current" - так как эта строчка кода может быть выполнена на любом потоке
         */
        print(Task.currentPriority)
        let author1 = "Author1 : \(Thread.current)"
        self.dataArray.append(author1)
        //try? await Task.sleep(nanoseconds: 2_000_000_000)
        try? await doSomething()
        /*
         с введением swift6 нельзя использовать в асинхронной функции "Thread.current" - так как эта строчка кода может быть выполнена на любом потоке
         */
        let author2 = "Author2 : \(Thread.current)"
        //переход на главный поток
        await MainActor.run {
            self.dataArray.append(author2)
            let author3 = "Author3 : \(Thread.current)"
            self.dataArray.append(author3)
        }
    }
    
    func doSomething() async throws {
        print("HI")
    }
}

struct AsyncAwait: View {
    @StateObject private var viewModel = AsyncAwaitViewModel()
    var body: some View {
        List {
            ForEach(viewModel.dataArray, id: \.self) { data in
                Text(data)
            }
        }
        .onAppear{
            Task{
                await viewModel.addAuthor1()
            }
        }
//        .onAppear{
//            viewModel.addTitle()
//            viewModel.addTitle2()
//        }
    }
}

#Preview {
    AsyncAwait()
}
