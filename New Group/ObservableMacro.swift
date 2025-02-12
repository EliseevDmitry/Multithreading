//
//  ObservableMacro.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 12.02.2025.
//

import SwiftUI

actor TitleDataBase {
    func getNewTitle() -> String {
        "Some new title!"
    }
}

/*
//реализация через ObservableObject
//если тут не ставим @MainActor - тогда на обновлении UI (updateTitle() - возникает проблема с Main потоком, однако при использовании макроса - будет другая проблема - ошибку не выдаст и надо работать - "руками")
@MainActor
class ObservableMacroViewModel: ObservableObject {
    let database = TitleDataBase()
    @Published var title: String = "Starting title"
    
    func updateTitle() async {
        title = await database.getNewTitle()
    }
}
*/

//реализация через макрос
//в старых версиях - @MainActor - не прокатывал (приходилось помечать или переменную или функцию, или замыкание Task - для не асинхронного вызова)

@Observable class ObservableMacroViewModel{
    //не наблюдаемые переменные помечаются -  @ObservationIgnored
    @ObservationIgnored let database = TitleDataBase()
    var title: String = "Starting title"
    
    @MainActor
    func updateTitle() async {
        title = await database.getNewTitle()
        //из примера видим - что поток отличный от Main
        print(Thread.current)
    }
    
    func updateTitle2() {
        Task { @MainActor in
            title = await database.getNewTitle()
            print(Thread.current)
        }
    }
    
}

struct ObservableMacro: View {
    /*
    //реализация через ObservableObject
    @StateObject private var viewModel = ObservableMacroViewModel()
     */
    
    //реализация через макрос
    @State private var viewModel = ObservableMacroViewModel()
    var body: some View {
        Text(viewModel.title)
        /*
        //асинхронный вызов
            .task {
                await viewModel.updateTitle()
            }
         */
            .onAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                    //работает на Main
                    viewModel.updateTitle2()
                }
            }
    }
}

#Preview {
    ObservableMacro()
}
