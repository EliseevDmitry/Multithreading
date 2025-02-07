//
//  GlobalActor.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 07.02.2025.
//

import SwiftUI

/*
 Единственный во всем приложении - Singletone
 @GlobalActor - globally-unique actor
 */

//Методы actor, могут выполняться в любом потоке (основной или фоновый), в зависимости от того, откуда они вызываются, но всегда с соблюдением правил асинхронности и потокобезопасности

//нужно контролировать что бы был единственный экземпляр MyNewDataManager()!!!
@globalActor final class MyFirstGlobalActor {
    //@globalActor - должен рeализовать 1 some Actor
    static var shared = MyNewDataManager()
}

//@MainActor - уже созданный аналог - @globalActor, единственное отличие - @MainActor - это всегда Main Thread

actor MyNewDataManager {
    
    func getDataFromDataBase() -> [String] {
        return [
            "One",
            "Two",
            "Three",
            "Four",
            "Five",
            "Six"
        ]
    }
}

//класс может быть - @MainActor class GlobalActorViewModel: ObservableObject {
//класс может быть - @MyFirstGlobalActor class GlobalActorViewModel: ObservableObject {
//также внутри при - @MainActor и/или @MyFirstGlobalActor - функции и переменные могут быть "nonisolated"
class GlobalActorViewModel: ObservableObject {
    //отмечаем переменную - которая обновляет UI как переменную обновляемую на главном потоке, также мы можем указать весь class как @MainActor
    @MainActor @Published var dataArray: [String] = []
    
    //let manager = MyNewDataManager()
    //при реализации @globalActor - обращаемся к actor через @globalActor
    let manager = MyFirstGlobalActor.shared
    
    //за счет @MyFirstGlobalActor - мы помещаем функцию func getData() async {} на actor
    @MyFirstGlobalActor func getData() async {
        
        //HEAVY COMPLEX METHODS
        //предположим что тут выполняется тяжелая задача, но есть проблема в том что вызов этой функции происходит в представлении GlobalActor: View - что является потоком Main (и это проблема!!!)
        //Global actor - позволяет отправить функцию getData() -> в actor (хотя функция не являетcя элементом actor-a)
        
        let data = await manager.getDataFromDataBase()
        //переход на главный поток
        await MainActor.run {
            self.dataArray = data
        }
        
    }
    
}

struct GlobalActorProject: View {
    @StateObject private var viewModel = GlobalActorViewModel()
    var body: some View {
        ScrollView {
            VStack{
                ForEach (viewModel.dataArray, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
            .padding(.top, 100)
        }
        .task {
            await viewModel.getData()
        }
    }
}

#Preview {
    GlobalActorProject()
}
