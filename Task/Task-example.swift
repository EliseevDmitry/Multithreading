//
//  Task-example.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 02.02.2025.
//

import SwiftUI


final class TaskExampleViewModel: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var image2: UIImage? = nil
    
    func fetchImage() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        do{
            guard let url = URL(string: "https://picsum.photos/200") else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            //переход в main поток
            await MainActor.run {
                self.image = UIImage(data: data)
                print("image downloaded successfully")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fetchImage2() async {
        do{
            guard let url = URL(string: "https://picsum.photos/200") else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            //переход в main поток
            await MainActor.run {
                self.image2 = UIImage(data: data)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

struct TaskStartPage: View {
    var body: some View {
        NavigationView {
            //так как у нас в функции fetchImage() - задержка в 5 секунд мы  можем перейти и вернуться назад (но загрузка не прервется - а будет происходить за "кадром")
            NavigationLink("Go to next screen ->") {
                Task_example()
            }
        }
    }
}

struct Task_example: View {
    @StateObject private var viewModel = TaskExampleViewModel()
    //@State private var fetchImageTask: Task<(), Never>? = nil
    var body: some View {
        VStack(spacing: 40) {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            if let image = viewModel.image2 {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            
        }
        .onAppear{
            /*
             
             //Последовательное выполнение загрузки
             //в этой истории загрузка идет последовательно сначала fetchImage(), после удачного выполнения -> fetchImage2()
             
             Task{
             await viewModel.fetchImage()
             await viewModel.fetchImage2()
             }
             */
            
            /*
             
             //условное разделение задач
             //небольшое решение проблемы
             
             Task{
             createThreadPriority(number: "1")
             await viewModel.fetchImage()
             }
             Task{
             createThreadPriority(number: "2")
             await viewModel.fetchImage2()
             }
             */
            
            
            /*
             //Приоритеты задач
             
             Task(priority: .userInitiated) {
             descriptionPriority(priority: ".userInitiated")
             }
             
             Task(priority: .high) {
             //try? await Task.sleep(nanoseconds: 2_000_000_000)
             //Приостанавливает текущую задачу и позволяет выполнять другие задачи. Возвращаясь к текущей задачи (как бы пропуская накопившиеся с более низкими приоритетами - вперед).
             await Task.yield()
             descriptionPriority(priority: ".high")
             }
             Task(priority: .medium) {
             descriptionPriority(priority: ".medium")
             }
             Task(priority: .utility) {
             descriptionPriority(priority: ".utility")
             }
             
             Task(priority: .low) {
             descriptionPriority(priority: ".low")
             }
             Task(priority: .background) {
             descriptionPriority(priority: ".background")
             }
             
             */
            
            /*
             Task(priority: .low) {
             descriptionPriority(priority: ".low")
             
             //задача наследуют приоиритет родителя  Task(priority: .low)
             Task {
             descriptionPriority(priority: ".high")
             }
             
             //отсоединение задачи от приоритета родителя - но Apple рекомендует это делать
             Task.detached {
             print(Task.currentPriority)
             }
             
             }
             */
            
            /*
             //До IOS15 требовалось создавать переменную и отменять в методе onDisappear{}
             //@State private var fetchImageTask: Task<(), Never>? = nil
             //пишем отмену задачи
             //до появления .task {} в IOS15
             self.fetchImageTask = Task {
             await viewModel.fetchImage()
             }
             */
        }
        
        
        /*
         //До IOS15 требовалось создавать переменную и отменять в методе onDisappear{}
         //@State private var fetchImageTask: Task<(), Never>? = nil
         
         .onDisappear{
         //отмена загрузки до IOS15
         self.fetchImageTask?.cancel()
         }
         */
        
        
        .task {
            await viewModel.fetchImage()
            
            //под капотом теперь //self.fetchImageTask?.cancel()
            //длинные задачи могут быть не завершены, поэтому требуется дополнительно проверять
            /*
             for x in array {
             //long work
             
             try Task.checkCancellation()
             }
             */
        }
    }
    
    private func createThreadPriority(number: String){
        print("\(Thread.current) - IMAGE-\(number)")
        print("\(Task.currentPriority) - IMAGE-\(number)")
    }
    
    private func descriptionPriority(priority: String){
        print("\(priority) - \(Thread.current) - \(Task.currentPriority.rawValue)")
    }
}

#Preview {
    Task_example()
}
