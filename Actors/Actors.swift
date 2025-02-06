//
//  Actors.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 06.02.2025.
//

import SwiftUI

class MyDataManager {
    static let instance = MyDataManager()
    private init() {}
    
    var data: [String] = []
    
    //WARNING: ThreadSanitizer: Swift access race (pid=6768)
    //имитация ошибки "access race", оба потока пытаются обратиться к объекту по ссылке в Heap
    //длz обнаружения ошибок в консоле связанных с "access race" - требуется в Edit Scheme -> Run -> установить галочку "Threed Sanitizer"!!!
    
    /*
     решаем вопрос потокобезопасности class, без actor
     1. Создаем очередь, и отправляем все задачи на нее.
     2. Создаем асинхронную функцию getRandomDataAsync()
     */
    
    private let queue = DispatchQueue(label: "MyDataManager")
    
    func getRandomDataAsync(completeonHandler: @escaping (_ title: String?) -> Void) {
        queue.async {
            self.data.append(UUID().uuidString)
            print(Thread.current)
            completeonHandler(self.data.randomElement())
        }
    }
    
    func getRandomData() -> String? {
        self.data.append(UUID().uuidString)
        print(Thread.current)
        return data.randomElement()
    }
}

//решение того же вопроса с использованием actor
actor MyActorDataManager {
    static let instance = MyActorDataManager()
    private init() {}
    
    var data: [String] = []
    
    func getRandomData() -> String? {
        self.data.append(UUID().uuidString)
        print(Thread.current)
        return data.randomElement()
    }
    
    //Пример вызова функции только в асинхронной семантике в Task{}
    func getName1() -> String {
        return "Name 1 async"
    }
    
    //nonisolated внутри actor - далает функцию или переменную не async -> для использования без await!!! Пример вызова функции в .onAppear{}
    nonisolated func getName2() -> String {
        return "Name 2 NON async"
    }
}

struct HomeView: View {
    //работа с class
    //let manager = MyDataManager.instance
    
    //работа с actor
    let manager = MyActorDataManager.instance
    @State private var text: String = ""
    let timer = Timer.publish(every: 0.1, tolerance: nil, on: .main, in: .common, options: nil).autoconnect()
    var body: some View {
        ZStack {
            Color.gray.opacity(0.8)
            Text(text)
                .font(.headline)
        }
        .onReceive(timer) { _ in
            /*
             Эксперимент с "access race"
             DispatchQueue.global(qos: .background).async {
             if let data = manager.getRandomData() {
             DispatchQueue.main.async {
             self.text = data
             }
             }
             }
             */
            
            /*
             //решение проблемы без actor
             DispatchQueue.global(qos: .background).async {
             manager.getRandomDataAsync(completeonHandler: { title in
             if let text = title {
             DispatchQueue.main.async {
             self.text = text
             }
             }
             })
             }
             */
            Task{
                if let data = await manager.getRandomData() {
                    await MainActor.run {
                        self.text = data
                    }
                }
            }
        }
    }
}

struct BrowseView: View {
    //работа с class
    //let manager = MyDataManager.instance
    
    //работа с actor
    let manager = MyActorDataManager.instance
    @State private var text: String = ""
    @State private var startText: String = ""
    @State private var isLoading: Bool = false
    let timer = Timer.publish(every: 0.1, tolerance: nil, on: .main, in: .common, options: nil).autoconnect()
    var body: some View {
        ZStack {
            Color.yellow.opacity(0.8)
            
            Text(text)
                .font(.headline)
            Text(startText)
                .font(.headline)
                .offset(y: 100)
        }
        .onReceive(timer) { _ in
            /*
             Эксперимент с "access race"
             DispatchQueue.global(qos: .background).async {
             if let data = manager.getRandomData() {
             DispatchQueue.main.async {
             self.text = data
             }
             }
             }
             */
            
            /*
             //решение проблемы без actor
             DispatchQueue.global(qos: .background).async {
             manager.getRandomDataAsync(completeonHandler: { title in
             if let text = title {
             DispatchQueue.main.async {
             self.text = text
             }
             }
             })
             }
             */
            Task{
                if let data = await manager.getRandomData() {
                    await MainActor.run {
                        self.text = data
                    }
                }
                //пример работы await функции
                if !isLoading {
                    await startText = startText + manager.getName1()
                    isLoading.toggle()
                }
            }
        }
        .onAppear{
            startText = startText + manager.getName2()
        }
    }
}


struct Actors: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
        }
    }
}

#Preview {
    Actors()
}


//Проверить работу - Previewable
//#Preview {
//    @Previewable @State var count = 0
//    CounterView(count: $count)
//}
