//
//  RefrashhableProject.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 07.02.2025.
//

import SwiftUI

final class RefrashhableDataService {
    func getData() async throws -> [String] {
        //сделали эмуляцию ожидания сервера для .refreshable
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return ["Apple", "Banana", "Orange"].shuffled()
    }
}

@MainActor
final class RefrashhableProjectViewModel: ObservableObject {
    @Published private(set) var items: [String] = []
    let manager = RefrashhableDataService()
    func loadData() {
        Task{
            do{
                items = try await manager.getData()
            } catch {
                print(error)
            }
        }
    }
    
    func loadDataProgress() async {
        do{
            items = try await manager.getData()
        } catch {
            print(error)
        }
    }
}

struct RefrashhableProject: View {
    @StateObject private var viewModel = RefrashhableProjectViewModel()
    var body: some View {
        NavigationStack{
            ScrollView {
                VStack{
                    ForEach (viewModel.items, id: \.self) {item in
                        Text(item)
                            .font(.headline)
                    }
                }
            }
            .refreshable {
                //эта реализация показывает как модификатор работает с await методом, ProgressView вращается пока данные не загрузятся
                await viewModel.loadDataProgress()
                //при использовании синхронной функции - идет моментальное обновление данных без вращающегося ProgressView
            }
            .navigationTitle("refreshable")
            .onAppear{
                //плохая практика передавать во view асинхронные методы
                //дублирующая функция loadData() и loadDataProgress() async
                 viewModel.loadData()
            }
        }
    }
}

#Preview {
    RefrashhableProject()
}
