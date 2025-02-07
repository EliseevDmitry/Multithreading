//
//  MVVMTemplateProject.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 07.02.2025.
//

import SwiftUI

final class MyManagerClass {
    func getData() async throws -> String {
        "Some class Data!"
    }
}

actor MyManagerActor {
    func getData() async throws -> String {
        "Some actor Data!"
    }
}

//можно установить на class ViewModel - так как этот слой всегда отвечает за обновление UI
@MainActor
final class MVVMTemplateProjectViewModel: ObservableObject {
    let managerClass = MyManagerClass()
    let managerActor = MyManagerActor()
    
    //@MainActor - можно установить на переменную ответственную за обновление UI
    @Published private(set) var myData: String = "Starting text"
    
    //переменная созданных задач - для управления и очистки
    private var tasks: [Task<Void, Never>] = []
    
    //функция очистки задач
    func cancelTasks() {
        //отменяем все tasks
        tasks.forEach({$0.cancel()})
        
        //очищаем массив
        tasks = []
    }
    
    //все события UI обрабатываются ViewModel
    //@MainActor - можно установить на функцию ответственную за обновление UI
    func onCallToActionButtonPressed() {
        let task = Task {
            do {
                //myData = try await managerClass.getData()
                myData = try await managerActor.getData()
            } catch {
                print(error)
            }
        }
        tasks.append(task)
    }
}



struct MVVMTemplateProject: View {
    @StateObject private var viewModel = MVVMTemplateProjectViewModel()
    var body: some View {
        Button("click me - \(viewModel.myData)"){
            //очень хорошая практика - выносить реализацию функции во viewModel
            viewModel.onCallToActionButtonPressed()
        }
    }
}

#Preview {
    MVVMTemplateProject()
}
