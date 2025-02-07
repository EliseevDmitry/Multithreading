//
//  StrongWeakProject.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 07.02.2025.
//

/*
 В async/await - мы не занимаемся управлением strong/weak ссылками
 Мы занимаемся управлением Task{}, .task - они отвечают за удаление сильных связей
 */

import SwiftUI

final class StrongSelfDataService {
    func getData() async -> String {
        "Updated data!"
    }
}

final class StrongSelfViewModel: ObservableObject {
    @Published var data: String = "Some title"
    let dataService = StrongSelfDataService()
    
    //переменная созданных задач - для управления и очистки
    private var someTask: Task<Void, Never>? = nil
    private var myTasks: [Task<Void, Never>] = []
    
    //функция очистки задач
    func cancelTasks() {
        //отменяем все tasks
        myTasks.forEach({$0.cancel()})
        
        //очищаем массив
        myTasks = []
        
        someTask?.cancel()
        someTask = nil
    }
    
    //Эта реализация предполагает сильную strong ссылку
    func updateData() {
        Task{
            data = await dataService.getData()
        }
    }
    
    //Эта реализация предполагает сильную strong ссылку
    func updateData2() {
        Task{
            self.data = await dataService.getData()
        }
    }
    
    //Эта реализация предполагает сильную strong ссылку
    func updateData3() {
        //добавляем в единичную переменную (для управления Task{} )
        someTask = Task{ [self] in
            self.data = await dataService.getData()
        }
    }
    
    //Эта реализация предполагает слабую weak ссылку
    func updateData4() {
        Task{ [weak self] in
            if let data = await self?.dataService.getData() {
                self?.data = data
            }
        }
    }
    
    func updateData5() {
        Task{
            self.data = await self.dataService.getData()
        }
    }
    
    func updateData6() {
        let task1 = Task{
            self.data = await self.dataService.getData()
        }
        myTasks.append(task1)
        let task2 = Task{
            self.data = await self.dataService.getData()
        }
        myTasks.append(task2)
    }
    
    //Мы специально не реализуем механизм для отмены тут Task - для сохранения сильной strong ссылки (updateData7(), updateData7(8)
    func updateData7() {
        Task{
            self.data = await self.dataService.getData()
        }
        Task.detached{
            self.data = await self.dataService.getData()
        }
    }
    
    func updateData8() async {
        self.data = await self.dataService.getData()
    }
}

struct StrongWeakProject: View {
    @StateObject private var viewModel = StrongSelfViewModel()
    var body: some View {
        Text(viewModel.data)
            .onAppear{
                viewModel.updateData()
            }
            .onDisappear{
                //удаление сильных ссылок - управление на уровне Task{}
                viewModel.cancelTasks()
            }
            .task {
                //этот модификатор - автоматически удаляет ссильные ссылки за нас - вносить Task в переменную myTasks не требуется, также как и вызывать в методе  .onDisappear{} функции - viewModel.cancelTasks()
                await viewModel.updateData8()
            }
    }
}

#Preview {
    StrongWeakProject()
}
