//
//  SendableProject.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 07.02.2025.
//

import SwiftUI

actor CurrentUserManager {
    func updateDataBase(userInfo: MyCurrentStruct){
        
    }
    
    func updateDataBase2(userInfo: MyCurrentClass){
        
    }
    
    func updateDataBase3(userInfo: MyCurrentClass2){
        
    }
}


/*
 Sendable - протокол проверки потокобезопасности (при отправки на actor)
 Основная идея заключается в том, что если отправить на actor любой (reference type) - это не потокобезопастно, так как он хранится на Heap и на него может быть ссылается несколько Threads
 */

struct MyCurrentStruct: Sendable {
    let name: String
    var age: Int
}

//когда мы делаем class подписанным под протокол Sendable, мы его "финалим" - защищаем от наследования - final
//во-вторых в class подписанном на протокол Sendable не может быть переменных var -> только let!!! (есть исключение ниже!)
final class MyCurrentClass: Sendable {
    let name: String = "Nastya"
    //var age: Int = 0
}


//@unchecked Sendable - обозначает на проверять на Sendable
//очень опасная практика - ответственность за потокобезопасность лежит на программисте
final class MyCurrentClass2: @unchecked Sendable {
    //есть возможность применять var, но изменять их желательно и можно только изнутри!!!
    private var name: String
    private var age: Int
    
    //создается асинхронная очередь, для обеспечения потокобезопасности
    let queue = DispatchQueue(label: "unchecked")
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    //изменение var - происходит внутри асинхронной очереди
    func updateData(name: String, age: Int) {
        queue.async {
            self.name = name
            self.age = age
        }
    }
    
}



final class SendableProjectViewModel: ObservableObject {
    let manager = CurrentUserManager()
    
    func updateCurrentUserInfo() async {
        //пример передачи на actor (value type) подписанной под протокол Sendable
        let info = MyCurrentStruct(name: "Dima", age: 39)
        await manager.updateDataBase(userInfo: info)
        
        //пример работы передачи на actor (reference type) подписанный под протокол Sendable
        let info2 = MyCurrentClass()
        await manager.updateDataBase2(userInfo: info2)
        
        
        let info3 = MyCurrentClass2(name: "Sveta", age: 54)
        await manager.updateDataBase3(userInfo: info3)
    }
}

struct SendableProject: View {
    @StateObject private var viewModel = SendableProjectViewModel()
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .task {
                await viewModel.updateCurrentUserInfo()
            }
    }
}

#Preview {
    SendableProject()
}
