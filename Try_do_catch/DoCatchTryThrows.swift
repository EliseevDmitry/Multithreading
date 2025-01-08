//
//  ContentView.swift
//  Multithreading
//
//  Created by Dmitriy Eliseev on 08.01.2025.
//

import SwiftUI

class DoCatchTryThrowsDataManager {
    let isActive = false
    
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
}


struct DoCatchTryThrows: View {
    @StateObject private var viewModel = DoCatchTryThrowsViewModel()
    var body: some View {
        VStack {
            Text(viewModel.text)
                .frame(width: 300, height: 300)
                .background(.blue)
                .onTapGesture {
                    viewModel.fetchTitle()
                }
        }
        .padding()
    }
}

#Preview {
    DoCatchTryThrows()
}
