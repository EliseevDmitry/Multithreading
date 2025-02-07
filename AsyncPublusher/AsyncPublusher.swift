//
//  AsyncPublusher.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 07.02.2025.
//

import SwiftUI
//смотрим как на аналог - технологию combine
import Combine

actor AsyncPublusherDataManager {
    @Published var myData: [String] = []
    
    func addData() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Apple")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Banana")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Orange")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Watermelon")
    }
    
    func addNewData() async {
        myData.append("tomato")
    }
}

class AsyncPublusherViewModel: ObservableObject {
    @MainActor @Published var dataArray: [String] = []
    let manager = AsyncPublusherDataManager()
    //для работы с Combine
    var cancellables = Set<AnyCancellable>()
    func start() async {
        await manager.addData()
    }
    
    func addData() {
        Task {
            await manager.addNewData()
        }
    }
    
    init(){
        addSubscribers()
    }
    
    //реализация с использованием async/await
    private func addSubscribers() {
        Task {
            await MainActor.run {
                self.dataArray = ["ONE"]
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            for await value in await manager.$myData.values {
                await MainActor.run {
                    self.dataArray = value
                }
            }
            //этот код не выполнится никогда - потому что предыдущий цикл всегда будет await - и опрашивать изменения (его можно отменять - это рассмотрим в теме Strong/weak)
            //так же решение - убрать нижний блок кода в отдельный Task {}
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                self.dataArray = ["TWO"]
            }
        }
    }
    
    /*
     реализация с использованием фрэймворка Combine
     private func addSubscribers() {
     manager.$myData
     .receive(on: DispatchQueue.main, options: nil)
     .sink { dataArray in
     self.dataArray = dataArray
     }
     .store(in: &cancellables)
     }
     */
}

struct AsyncPublusher: View {
    @StateObject private var viewModel = AsyncPublusherViewModel()
    var body: some View {
        ScrollView {
            Button("AddData"){
                viewModel.addData()
            }
            VStack {
                ForEach (viewModel.dataArray, id: \.self) {item in
                    Text(item)
                        .font(.headline)
                }
            }
        }
        .onAppear{
            Task{
                await viewModel.start()
            }
        }
    }
}

#Preview {
    AsyncPublusher()
}
