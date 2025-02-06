//
//  StructClassActor.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 03.02.2025.
//

//https://www.backblaze.com/blog/whats-the-diff-programs-processes-and-threads/
//https://stackoverflow.com/questions/24232799/why-choose-struct-over-class/24232845
//https://stackoverflow.com/questions/27441456/swift-stack-and-heap-understanding
//https://stackoverflow.com/questions/24217586/structure-vs-class-in-swift-language/59219141#59219141
//https://medium.com/@vinayakkini/swift-basics-struct-vs-class-31b44ade28ae
//https://stackoverflow.com/questions/24217586/structure-vs-class-in-swift-language
//https://blog.onewayfirst.com/ios/posts/2019-03-19-class-vs-struct/

/*
 
VALUE TYPES:
- Struct, Enum, String, Int, etc.
- Stored in the Stack
- Faster
- Thread safe!
- When you assign or pass value type a new copy of data is created

 REFERENCE TYPES:
- Class, Function, Actor
- Stored in the Heap
- Slower, but synchronized
- NOT Thread safe!
- When you assign or pass reference type a new reference to original instance will be created (pointer)
 
 STRUCT:
 - Based on VALUES
 - Can me mutated
 - Stored in the Stack!

 CLASS:
 - Based on REFERENCES (INSTANCES)
 - Stored in the Heap!
 - Inherit from other classes
 
 ACTORS:
 Same as Class, but thread safe!
 
 -----------------------------------
 
 Structs: Data Models, Views
 Classes: ViewModels
 Actors: Shared Manager and DataStore
 
 */

import SwiftUI


//хорошая практика делать DataManager - actor из-за асинхронности работы и работы в многопоточной среде
actor StructClassActorDataManager {
    //...
}

// View модель - это класс передающийся по ссылке, "ObservableObject"
class StructClassActorViewModel: ObservableObject {
    @Published var title: String = ""
    
    init(title: String) {
        self.title = title
        print("ViewModel INIT")
    }
}

struct StructClassActor: View {
    @StateObject private var viewModel = StructClassActorViewModel(title: "INIT VIEWMODEL")
    let isActive: Bool
    
    init (isActive: Bool) {
        self.isActive = isActive
        print("View INIT")
    }
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .background(isActive ? Color.red : Color.blue)
            .onAppear{
                runTest()
            }
    }
}

//Этот пример показывает как при перерисовки экрана обновляется только структура "StructClassActor" - идет инициализация "View INIT", а class - который является (referense type) - инициализируется при загрузки - один раз!
struct StructClassActorHomeView: View {
    @State private var isActive: Bool = false
    var body: some View {
        StructClassActor(isActive: isActive)
            .onTapGesture {
                isActive.toggle()
            }
    }
}

struct MyStruct {
    var title: String
}

//Immutable struct - максисмально показывает работу конструкции структур SwiftUI
struct CustomStruct {
    let title: String
    //функция заменяет структуру в памяти
    func updateTitle(newTitle: String) -> CustomStruct {
        CustomStruct(title: newTitle)
    }
}

struct MutatingStruct {
    private(set) var title: String
    
    init(title: String) {
        self.title = title
    }
    //функция изменяет значение поля внутри самой себя
    mutating func updateTitle(newTitle: String) {
        title = newTitle
    }
}

class MyClass {
    var title: String = ""
    
    init(title: String) {
        self.title = title
    }
}

//Интересная особенность - у каждого потока Thread - свой Stack, Heap - у всех одна (тут и возникает - потокобезопасность и все остальное).

//actor и class - почти одно и тоже!!!, разница в том, что actor (потокобезопасен) - а так это тоже (referense type) - экземпляр которого храниться на Heap!!!
//actor - решает проблему data races (когда идет обращение на Heap к одному и тому же объекту)
//actor - работает в асинхронной среде

actor Myactor {
    var title: String
    init(title: String) {
        self.title = title
    }
    func updateTitle(newTitle: String){
        title = newTitle
    }
}

extension StructClassActor {
    private func runTest() {
        print("Test started!")
        structTest()
        myDivider()
        classTest()
        myDivider()
        structTest2()
        myDivider()
        actorTest1()
    }
    
    private func structTest() {
        let objectA = MyStruct(title: "Starting title")
        print("ObjectA:", objectA.title)
        print("Pass the VALUES of objectA to objectB")
        //очень важно обратить внимание - что тут мы используем var - так как мы перезаписываем структуру (в классах, изменяя свойство - объект может храниться в let)
        var objectB = objectA
        print("ObjectB:", objectB.title)
        objectB.title = "NEW Second title!"
        print("ObjectB title changed")
        print("ObjectA:", objectA.title)
        print("ObjectB:", objectB.title)
    }
    
    //основная идея - показать изменения полей структуры (напрямую и через метод)
    private func structTest2() {
        print ("structTest2")
        var struct1 = MyStruct(title: "Title1")
        print ("Struct1: ", struct1.title)
        struct1.title = "Title2"
        print("Struct1: ", struct1.title)
        var struct2 = CustomStruct(title: "Title1")
        print("Struct2: ", struct2.title)
        struct2 = CustomStruct(title: "Title2")
        print ("Struct2: ", struct2.title)
        var struct3 = CustomStruct (title: "Title1")
        print("Struct3: ", struct3.title)
        withUnsafePointer(to: &struct3) { pointer in
            print("Address of myVariable: \(pointer)")
        }
        struct3 = struct3.updateTitle(newTitle: "Title2")
        print ("Struct3: ", struct3.title)
        withUnsafePointer(to: &struct3) { pointer in
            print("Address of myVariable: \(pointer)")
        }
        var struct4 = MutatingStruct (title: "Title1")
        print("Struct4: ", struct4.title)
        withUnsafePointer(to: &struct4) { pointer in
            print("Address of myVariable: \(pointer)")
        }
        struct4.updateTitle(newTitle: "Title2")
        print ("Struct4: ", struct4.title)
        withUnsafePointer(to: &struct4) { pointer in
            print("Address of myVariable: \(pointer)")
        }
    }
    
    func myDivider(){
        print("""
-----------------------------------
""")
    }
    
    private func classTest() {
        let objectA = MyClass(title: "Starting title")
        print("ObjectA:", objectA.title)
        print("Pass the VALUES of objectA to objectB")
        //очень важно обратить внимание - что тут мы используем let!!!
        let objectB = objectA
        print("ObjectB:", objectB.title)
        objectB.title = "NEW Second title!"
        print("ObjectB title changed")
        //и ObjectA: и ObjectB: - имеют -> "NEW Second title!" (referense type)
        print("ObjectA:", objectA.title)
        print("ObjectB:", objectB.title)
    }
    
    //actor - работает в асинхронной среде (и если мы что то хотим - от actor - нам приходится этого ожидать - "await")
    //actor - потокобезопастный!!!
    private func actorTest1() {
        Task {
            print ("actorTest1")
            let objectA = Myactor(title: "Starting title")
            await print("ObjectA:", objectA.title)
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            print("Pass the VALUES of objectA to objectB")
            //очень важно обратить внимание - что тут мы используем let!!!
            let objectB = objectA
            await print("ObjectB:", objectB.title)
            await objectB.updateTitle(newTitle: "NEW Second title!")
            print("ObjectB title changed")
            //и ObjectA: и ObjectB: - имеют -> "NEW Second title!" (referense type)
            await print("ObjectA:", objectA.title)
            await print("ObjectB:", objectB.title)
        }
    }
    
}

#Preview {
    StructClassActor(isActive: true)
}
