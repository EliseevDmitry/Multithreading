//
//  ContentView.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 08.01.2025.
//

import SwiftUI

class DoCatchTryThrowsDataManager {
    var isActive = false
    
    func getTitle() -> String {
        "New text"
    }
    
    func getTitle2() -> (title: String?, error: Error?){
        if isActive {
            return ("New text", nil)
        } else {
            return (nil, URLError(.badURL))
        }
    }
    
    
    func getTitle3() -> Result<String, Error>{
        if isActive {
            return .success("New text")
        } else {
            return .failure(URLError(.appTransportSecurityRequiresSecureConnection))
        }
    }
    
    func getTitle4() throws -> String {
        if isActive {
            return "New text"
        } else {
            throw URLError(.badServerResponse)
        }
    }
    
    func getTitle5() throws -> String {
        throw URLError(.badServerResponse)
    }
    
}

class DoCatchTryThrowsViewModel: ObservableObject {
    @Published var text: String = "Statring text"
    let manager = DoCatchTryThrowsDataManager()
    
    func fetchTitle() {
        let newTitle = manager.getTitle()
        self.text = newTitle
    }
    
    func fetchTitle2() {
        let newTitle = manager.getTitle2()
        if let title = newTitle.title {
            self.text = title
        } else if let error = newTitle.error {
            self.text = error.localizedDescription
        }
    }
    
    func fetchTitle3() {
        let newTitle = manager.getTitle3()
        switch newTitle {
            
        case .success(let newTitle):
            self.text = newTitle
        case .failure(let error):
            self.text = error.localizedDescription
        }
    }
    
    //разворачиваем конструкцию с пробрасыванием ошибки func getTitle4() throws -> String
    func fetchTitle4() {
        do {
            let newTitle = try manager.getTitle4()
            self.text = newTitle
        } catch let error {
            self.text = error.localizedDescription
        }
    }
    
    /*
     func getTitle5() throws -> String - пробрасывает всегда ошибку
     Идея заключается в том что если развернуть через опциональный try?, то в случае если после ошибки будет еще код, он продолжет выполняться, если try будет не опциональный и произойдет ошибка, компилятор выбросит и не перейдет к следующему блоку кода
     */
    
    func fetchTitle5() {
        do {
            //тестим вручную try? и try
            let newTitle = try? manager.getTitle5()
            if let title = newTitle {
                self.text = title
            }
            //self.text = newTitle
            let finalTitle = try manager.getTitle4()
            self.text = finalTitle
        } catch let error {
            self.text = error.localizedDescription
        }
    }
 
}


struct DoCatchTryThrows: View {
    @StateObject private var viewModel = DoCatchTryThrowsViewModel()
    var body: some View {
        VStack {
            /*
             Вариант первый с возвращаемым значением func getTitle() -> String
             
             Text(viewModel.text)
             .frame(width: 200, height: 200)
             .background(.blue)
             .onTapGesture {
             viewModel.fetchTitle()
             }
             */
            
            /*
             Вариант 2 - func getTitle2() -> (title: String?, error: Error?)
             требуется изменить флаг var isActive = false / true
             
             Text(viewModel.text)
             .frame(width: 200, height: 200)
             .background(.green)
             .onTapGesture {
             viewModel.manager.isActive = true
             viewModel.fetchTitle2()
             }
             */
            
            
            /*
             Вариант 3 - func getTitle3() -> Result<String, Error>
             требуется изменить флаг var isActive = false / true
             
            Text(viewModel.text)
                .frame(width: 200, height: 200)
                .background(.green)
                .onTapGesture {
                    viewModel.manager.isActive = true
                    viewModel.fetchTitle3()
                }
             */
            
            /*
             Вариант 4 - func getTitle4() throws -> String / func getTitle5() throws -> String
             требуется изменить флаг var isActive = false / true
             Разбираем вариант с try? и просто try
             */
            Text(viewModel.text)
                .frame(width: 200, height: 200)
                .background(.green)
                .onTapGesture {
                    viewModel.manager.isActive = true
                    viewModel.fetchTitle5()
                } 
        }
        .padding()
    }
}

#Preview {
    DoCatchTryThrows()
}
